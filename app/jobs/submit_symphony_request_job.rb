# frozen_string_literal: true

##
# Rails Job to submit a Scan request to Symphony for processing
class SubmitSymphonyRequestJob < ApplicationJob
  queue_as :default

  # we pass the ActiveRecord identifier to our job, rather than the ActiveRecord reference.
  #   This is recommended as a Sidekiq best practice (https://github.com/mperham/sidekiq/wiki/Best-Practices).
  #   It also helps reduce the size of the Redis database (used by Sidekiq), which stores its data in memory.
  def perform(request_id, options = {})
    return true unless enabled?

    request = find_request(request_id)

    return true unless request

    Sidekiq.logger.info("Started SubmitSymphonyRequestJob for request #{request_id}")
    response = Command.new(request, options).execute!

    Sidekiq.logger.debug("Symphony response string: #{response}")
    request.merge_symphony_response_data(response.with_indifferent_access)
    request.save
    request.send_approval_status!
    Sidekiq.logger.info("Completed SubmitSymphonyRequestJob for request #{request_id}")
  end

  def find_request(request_id)
    Request.find(request_id)
  rescue ActiveRecord::RecordNotFound
    Honeybadger.notify(
      "Attempted to call Symphony for Request with ID #{request_id}, but no such Request was found."
    )
  end

  def enabled?
    true
    #Settings.symphony_api.enabled && Settings.symphony_api.url.present?
  end

  ##
  # Command to submit a Scan request to Symphony for processing
  class StoredProcedureCommand
    include ActiveSupport::Benchmarkable

    attr_reader :request, :options

    delegate :user, to: :request

    def initialize(request, options = {})
      @request = request
      @options = options
    end

    def execute!
      benchmark "Sending func_request_webservice_new.make_request with #{request_params.inspect}" do
        response = client.get('func_request_webservice_new.make_request', request_params)
        JSON.parse(response.body)['request_response'] || {}
      end
    end

    def request_params
      # NOTE:  any changes to params (new ones, key name changes) must be coordinated with
      # Symphony programmers
      patron_from_request.merge(items_from_request).merge(
        req_type: req_type
      ).reject { |_, v| v.blank? }
    end

    private

    def req_type
      case request
      when Scan
        'SCAN'
      when HoldRecall
        'HOLD'
      when Page, MediatedPage
        'PAGE'
      end
    end

    # rubocop:disable Metrics/AbcSize
    def patron_from_request
      {
        sunet_id: (user.webauth if user.webauth_user?),
        library_id: user.library_id,
        patron_name: (user.name if user.library_id.blank?),
        patron_email: (user.email_address if user.library_id.blank?),
        proxy_group: (user.proxy_access.name if request.proxy?)
      }
    end

    def items_from_request
      {
        ckey: request.item_id,
        items: barcodes.join('^') + '^',
        copy_note: (copy_notes.join('^') + '^' if copy_notes.present?),
        home_lib: request.origin,
        item_comments: request.item_comment,
        req_comment: request.request_comment,
        requested_date: request.created_at.strftime('%m/%d/%Y'),
        pickup_lib: (request.destination unless request.is_a? Scan),
        not_needed_after: request.needed_date&.strftime('%m/%d/%Y')
      }
    end
    # rubocop:enable Metrics/AbcSize

    def barcodes
      items = options[:barcodes]
      items ||= request.barcodes.reject(&:blank?)
      items = ['NO_ITEMS'] if items.blank?
      items
    end

    def copy_notes
      return if request.public_notes.blank?

      result = []
      request.public_notes.each do |barcode, note|
        result << "#{barcode}:#{note}" if barcodes.include? barcode
      end
      result
    end

    def client
      @client ||= Faraday.new(url: base_url)
    end

    def base_url
      Settings.symphony_api.url
    end

    def logger
      Rails.logger
    end
  end

  # Submit requests using Symws
  class SymWsCommand
    attr_reader :request, :options

    delegate :user, to: :request
    delegate :patron, to: :user

    def initialize(request, options = {})
      @request = request
      @options = options
    end

    def symphony_client
      @symphony_client ||= SymphonyClient.new
    end

    def bib_info(key)
      @bib_info ||= Hash.new do |h, k|
        h[k] = symphony_client.bib_info(key)
      end
      @bib_info[key]
    end

    def call_list(key)
      bib_info(key)&.dig('fields', 'callList', 0, 'key')
    end

    def execute!
      responses = request_params.map do |param|
        place_hold_response = symphony_client.place_hold(**param)
        message = place_hold_response.dig('messageList', 0, 'message')
        barcode = param.dig(:item, :itemBarcode) || param.dig(:item, :call, :key)

        if message == 'User already has a hold on this material' && param[:patron_barcode].match(/^HOLD@/)
          MultipleHoldsMailer.multiple_holds_notification(
            {
              barcode: barcode,
              c_key: request.item_id,
              patron_barcode: param[:patron_barcode],
              name: name,
              email: email,
              pickup_library: request.destination,
              item_library: request.origin
            }
          ).deliver_later
        end
        {
          barcode: barcode,
          msgcode: message || '209',
          response: place_hold_response
        }
      end
      {
        requested_items: responses
      }.merge(usererr)
    end

    def usererr
      return { usererr_code: 'U003', usererr_text: 'User is BLOCKED' } unless user.patron.good_standing?
      return { usererr_code: 'U004', usererr_text: 'User\'s privileges have expired' } if user.patron.expired?

      { usererr_code: nil, usererr_text: nil }
    end

    def item(barcode)
      item_return = {
        itemBarcode: barcode,
        holdType: 'TITLE'
      }
      current_location = SymphonyCurrLocRequest.new(barcode: barcode).current_location if barcode && request.is_a?(Scan)
      # FIXME: potentially unreachable code as we guard against this in Scannable.
      if request.is_a?(Scan) && ['INPROCESS', 'ON-ORDER'].include?(current_location)
        item_return[:holdType] = 'COPY'
      end
      item_return
    end

    def scan_destinations(barcode = nil)
      return {} unless request.is_a? Scan

      current_location = SymphonyCurrLocRequest.new(barcode: barcode).current_location if barcode
      if request.origin == 'SAL' && ['HY-PAGE-EA', 'ND-PAGE-EA'].include?(current_location)
        return {
          key: 'EAST-ASIA',
          patron_barcode: 'EAL-SCANREVIEW'
        }
      end
      SULRequests::Application.config.scan_destinations.fetch(request.origin) do
        {
          key: 'GREEN',
          patron_barcode: 'GRE-SCANDELIVER'
        }
      end
    end

    def patron_barcode
      case request
      when Scan
        # Scan patron barcodes use logic in #scan_destinations
        nil
      when HoldRecall
        request.user.library_id
      when Page, MediatedPage
        if patron.good_standing?
          request.user.library_id
        else
          pseudo_patron(request.destination)
        end
      end
    end

    def pseudo_patron(key)
      SULRequests::Application.config.pickup_library_pseudo_patrons[key] || 'HOLD@GR'
    end

    def comment
      [name, email].join(' ')
    end

    def name
      user.name || patron.display_name
    end

    def email
      user.email_address || patron.email
    end

    def request_without_barcode
      [{
        fill_by_date: request.needed_date,
        key: request.destination,
        recall_status: patron.fee_borrower? ? 'NO' : 'STANDARD',
        item: {
          call: {
            key: call_list(request.item_id),
            resource: '/catalog/call'
          },
          holdType: 'TITLE'
        },
        patron_barcode: patron_barcode,
        comment: comment,
        for_group: (request.proxy? || request.user.proxy?),
        force: true
      }.merge(scan_destinations)]
    end

    def barcodes
      if options[:barcode]
        request.barcodes.select do |barcode|
          options[:barcode].include?(barcode)
        end
      else
        request.barcodes
      end
    end

    def request_params
      return request_without_barcode if request.barcodes.empty? # case for no barcode items :(

      barcodes.map do |item|
        {
          fill_by_date: request.needed_date,
          key: request.destination,
          recall_status: patron.fee_borrower? ? 'NO' : 'STANDARD',
          item: item(item),
          patron_barcode: patron_barcode,
          comment: comment,
          for_group: (request.proxy? || request.user.proxy?),
          force: true
        }.merge(scan_destinations(item))
      end
    end
  end

  # rubocop:disable Naming/ConstantName
  Command = begin
    if Settings.symphony_api.adapter == 'symws'
      SubmitSymphonyRequestJob::SymWsCommand
    else
      SubmitSymphonyRequestJob::StoredProcedureCommand
    end
  end
  # rubocop:enable Naming/ConstantName
end
