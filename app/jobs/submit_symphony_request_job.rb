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
    attr_reader :request

    delegate :user, to: :request

    def initialize(request, options = {})
      @request = request
      @options = options
    end

    def symphony_client
      @symphony_client ||= SymphonyClient.new
    end

    def patron_profile
      @patron_profile ||= symphony_client.patron_info(request.user.library_id) || {} if request.user.library_id.present? || {}
    end

    def patron
      @patron ||= Patron.new(patron_profile)
    end

    def execute!
      responses = request_params.map do |param|
        symphony_client.place_hold(**param)
      end
      {
        requested_items: responses
      }
    end

    ##
    # TODO Get clarification from Shelly
    def item(item)
      item_return = {
        itemBarcode: item.barcode
      }
      if request.is_a?(Scan) || request.is_a?(Page)
        item_return['holdType'] = 'COPY'
      end
      item_return
    end

    def scan_stuff(item)
      return {} unless request.is_a? Scan

      current_location = SymphonyCurrLocRequest.new(barcode: item.barcode).current_location
      if current_location == 'SAL' && request.origin == 'SAL' && symphony_client.request_library == 'SAL'
        return {
          key: 'GREEN',
          patron_barcode: 'GRE-SCANDELIVER'
        }
      end
      if request.origin == 'SAL' && ['HY-PAGE-EA', 'ND-PAGE-EA'].include?(current_location)
        return {
          key: 'EAST-ASIA',
          patron_barcode: 'EAL-SCANREVIEW'
        }
      end
      {
        key: 'SAL3',
        patron_barcode: 'SAL3-SCANDELIVER'
      }
    end

    def patron_barcode
      case request
      when Scan
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
          bib: {
            key: request.item_id,
            resource: '/catalog/bib'
          },
          holdType: 'TITLE'
        },
        patron_barcode: patron_barcode,
        for_group: request.proxy? || request.user.proxy?,
        comment: comment
      }]
    end

    def request_params
      return request_without_barcode if request.holdings.empty? # case for no barcode items :(

      request.holdings.map do |item|
        {
          fill_by_date: request.needed_date,
          key: request.destination,
          recall_status: patron.fee_borrower? ? 'NO' : 'STANDARD',
          item: item(item),
          patron_barcode: patron_barcode,
          for_group: request.proxy? || request.user.proxy?,
          comment: comment
        }.merge(scan_stuff(item))
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
