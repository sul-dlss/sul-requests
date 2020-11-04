# frozen_string_literal: true

##
# Rails Job to submit a Scan request to Symphony for processing
class SubmitSymphonyRequestJob < ApplicationJob
  class SymphonyWebServiceAdapterError < StandardError; end

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
    Settings.symphony_api.enabled && Settings.symws.url.present?
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

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
    def execute!
      responses = place_hold_params.map do |param|
        place_hold_response = symphony_client.place_hold(**param)
        message = place_hold_response.dig('messageList', 0, 'message')
        msg_code = place_hold_response.dig('messageList', 0, 'code')&.sub(/^hatErrorResponse\./, '')
        barcode = param.dig(:item, :itemBarcode) || param.dig(:item, :call, :key)

        if message == 'User already has a hold on this material' && param[:patron_barcode].match(/^HOLD@/)
          notify_staff_for_multiple_holds(barcode) unless request.is_a?(Scan)
        end
        {
          barcode: barcode,
          msgcode: msg_code || '209',
          response: place_hold_response
        }
      end
      {
        requested_items: responses
      }.merge(usererr)
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity

    def request_params
      place_hold_params.map { |params| symphony_client.place_hold_params(params) }
    end

    private

    def symphony_client
      @symphony_client ||= options[:symphony_client] || SymphonyClient.new
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

    def notify_staff_for_multiple_holds(barcode)
      MultipleHoldsMailer.multiple_holds_notification(
        {
          barcode: barcode,
          c_key: request.item_id,
          patron_barcode: patron_barcode,
          name: name,
          email: email,
          pickup_library: request.destination,
          item_library: request.origin
        }
      ).deliver_later
    end

    def usererr
      return { usererr_code: 'U003', usererr_text: 'User is BLOCKED' } unless patron&.good_standing?
      return { usererr_code: 'U004', usererr_text: 'User\'s privileges have expired' } if patron&.expired?

      { usererr_code: nil, usererr_text: nil }
    end

    def item(barcode)
      item_return = {
        itemBarcode: barcode,
        holdType: 'TITLE'
      }
      item_return[:holdType] = 'COPY' if request.is_a?(Scan) || request.is_a?(MediatedPage)
      item_return
    end

    def scan_destinations(barcode = nil)
      return {} unless request.is_a? Scan

      current_location = CatalogInfo.find(barcode).current_location if barcode
      if request.origin == 'SAL' && ['HY-PAGE-EA', 'ND-PAGE-EA'].include?(current_location)
        return lookup_scan_destination('EAL_REVIEW_WORKFLOW')
      end

      lookup_scan_destination(request.origin) || lookup_scan_destination('GREEN')
    end

    def lookup_scan_destination(key)
      SULRequests::Application.config.scan_destinations.fetch(key)
    end

    # rubocop:disable Metrics/MethodLength
    def patron_barcode
      case request
      when Scan
        # Scan patron barcodes use logic in #scan_destinations
        nil
      when HoldRecall
        patron.barcode
      when Page, MediatedPage
        if patron&.good_standing?
          patron.barcode
        else
          pseudo_patron(request.destination)
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    def pseudo_patron(key)
      SULRequests::Application.config.pickup_library_pseudo_patrons[key] || 'HOLD@GR'
    end

    def comment
      [name, email].join(' ')
    end

    def name
      user.name || patron&.display_name
    end

    def email
      user.email_address || patron&.email
    end

    def request_without_barcode
      generic_request
        .merge({ item: {
                 call: {
                   key: call_list(request.item_id),
                   resource: '/catalog/call'
                 },
                 holdType: 'TITLE'
               } })
        .merge(scan_destinations)
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

    def generic_request
      {
        fill_by_date: request.needed_date,
        key: request.destination == 'SPEC-COLL' ? 'SPEC-DESK' : request.destination,
        recall_status: patron&.fee_borrower? ? 'NO' : 'STANDARD',
        patron_barcode: patron_barcode,
        comment: comment,
        for_group: (request.proxy? || request.user.proxy?),
        force: true
      }
    end

    def place_hold_params
      return [request_without_barcode] if request.barcodes.empty? # case for no barcode items :(

      barcodes.map do |barcode|
        generic_request
          .merge({ item: item(barcode) })
          .merge(scan_destinations(barcode))
      end
    end
  end

  unless Settings.symphony_api.adapter.to_s == 'symws'
    raise SymphonyWebServiceAdapterError, "#{Settings.symphony_api.adapter} is not a known Symphony Web Services Adapter"
  end

  Command = SubmitSymphonyRequestJob::SymWsCommand
end
