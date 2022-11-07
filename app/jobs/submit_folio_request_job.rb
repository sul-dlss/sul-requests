# frozen_string_literal: true

##
# Rails Job to submit a Scan request to Symphony for processing
class SubmitFolioRequestJob < ApplicationJob
  queue_as :default

  # we pass the ActiveRecord identifier to our job, rather than the ActiveRecord reference.
  #   This is recommended as a Sidekiq best practice (https://github.com/mperham/sidekiq/wiki/Best-Practices).
  #   It also helps reduce the size of the Redis database (used by Sidekiq), which stores its data in memory.
  def perform(request_id, options = {})
    return true unless enabled?

    request = find_request(request_id)

    return true unless request

    Sidekiq.logger.info("Started SubmitFolioRequestJob for request #{request_id}")
    response = Command.new(request, **options).execute!

    Sidekiq.logger.debug("Folio response string: #{response}")
    request.merge_symphony_response_data(FolioSymphonyResponseAdapter.new(response.with_indifferent_access))
    request.save
    request.send_approval_status!
    Sidekiq.logger.info("Completed SubmitFolioRequestJob for request #{request_id}")
  end

  def find_request(request_id)
    Request.find(request_id)
  rescue ActiveRecord::RecordNotFound
    Honeybadger.notify(
      "Attempted to call Symphony for Request with ID #{request_id}, but no such Request was found."
    )
  end

  # Submit requests using Symws
  class FolioCommand
    attr_reader :request, :folio_client, :barcode

    delegate :user, to: :request
    delegate :patron, to: :user

    def initialize(request, folio_client: nil, barcode: nil)
      @request = request
      @symphony_client = symphony_client || FolioClient.new
      @barcode = barcode
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def execute!
      response = folio_client.batch_request(request_params)

      # responses = response.map do |item|
      #   {
      #     barcode: barcode,
      #     msgcode: msg_code || '209',
      #     response: place_hold_response
      #   }
      # end

      {
        requested_items: responses
      }.merge(usererr || {})
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def request_params
      place_hold_params.map do |params|
        {
          id:,
          requestLevel:,
          requestType:,
          requesterId:,
          itemId:,
          instanceId:
          holdingsRecordId:,
          itemId:,
          fulfilmentPreference: 'Hold Shelf',
          requestExpirationDate:,
          instanceId:,

        }
        symphony_client.place_hold_params(**params)
      end
    end

    private

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
      # if there's no patron record attached to this user, don't bother
      # reporting any user status information
      return unless patron

      if patron.expired?
        { usererr_code: 'U004', usererr_text: 'User\'s privileges have expired' }
      elsif !patron.good_standing?
        { usererr_code: 'U003', usererr_text: 'User is BLOCKED' }
      end
    end

    def item(barcode)
      item_return = {
        itemBarcode: barcode,
        holdType: 'COPY'
      }
      item_return[:holdType] = 'TITLE' if request.is_a?(HoldRecall)
      item_return
    end

    def scan_destinations
      return {} unless request.is_a? Scan

      request.scannable_location_rule&.destination || Settings.default_scan_destination
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
      Settings.libraries[key]&.hold_pseudopatron || 'HOLD@GR'
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
      return request.barcodes unless @barcode

      request.barcodes.select do |barcode|
        @barcode == barcode
      end
    end

    def generic_request
      {
        fill_by_date: request.needed_date,
        key: request.destination == 'SPEC-COLL' ? 'SPEC-DESK' : request.destination,
        recall_status: patron&.fee_borrower? ? 'NO' : 'STANDARD',
        patron_barcode: patron_barcode,
        comment: comment
        # for_group: (request.proxy? || request.user.proxy?),
      }
    end

    def place_hold_params
      return [request_without_barcode] if request.barcodes.empty? # case for no barcode items :(

      barcodes.map do |barcode|
        generic_request
          .merge({ item: item(barcode) })
          .merge(scan_destinations)
      end
    end
  end

  Command = SubmitFolioRequestJob::FolioCommand

  def self.command
    Command
  end
end
