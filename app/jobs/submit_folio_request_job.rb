# frozen_string_literal: true

##
# Rails Job to submit a hold request to Folio for processing
class SubmitFolioRequestJob < ApplicationJob
  queue_as :default

  # we pass the ActiveRecord identifier to our job, rather than the ActiveRecord reference.
  #   This is recommended as a Sidekiq best practice (https://github.com/mperham/sidekiq/wiki/Best-Practices).
  #   It also helps reduce the size of the Redis database (used by Sidekiq), which stores its data in memory.
  def perform(request_id, options = {})
    request = find_request(request_id)

    return true unless request

    logger.info("Started SubmitFolioRequestJob for request #{request_id}")
    response = Command.new(request, logger:, **options).execute!

    logger.debug("FOLIO response: #{response}")

    request.merge_ils_response_data(FolioResponse.new(response.with_indifferent_access))
    request.save(validate: false) # By placing this request in the ILS, the item is no longer in a requestable state, so avoid validation.
    request.send_approval_status!
    logger.info("Completed SubmitFolioRequestJob for request #{request_id}")
  end

  def find_request(request_id)
    Request.find(request_id)
  rescue ActiveRecord::RecordNotFound
    Honeybadger.notify('Unable to find Request', context: { request_id: })
  end

  PsuedoPatron = Data.define(:id, :patron_comments) do
    def blocked?
      false
    end
  end

  # Submit a hold request to FOLIO
  class Command
    attr_reader :request, :folio_client, :barcode, :logger

    # @param [Request] request
    # @param [Logger] logger
    # @param [FolioClient] folio_client (nil)
    # @param [String] barcode (nil)
    def initialize(request, logger:, folio_client: nil, barcode: nil)
      @request = request
      @logger = logger
      @folio_client = folio_client || FolioClient.new
      @barcode = barcode
    end

    def execute!
      return place_title_hold if barcodes.blank?

      requested_items = barcodes.map do |barcode|
        create_item_circulation_request(barcode)
      end

      # See if patron was blocked, and record that in the response. This governs the email response,
      # so that it matches the ILS response from Symphony
      return { requested_items:, usererr_code: 'u003' } if patron.blocked?

      { requested_items: }
    end

    # Called by the debug views
    def request_params
      request.folio_command_logs.map(&:as_json)
    end

    private

    delegate :user, :scan_destination, to: :request
    delegate :request_policies, to: :folio_client

    # prevent delegating to a nil patron
    def patron_group_id
      patron&.patron_group_id
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def create_item_circulation_request(barcode)
      item = request.bib_data.items.find { |x| x.barcode == barcode }
      raise 'Item not found' unless item

      create_log(barcode:, item_id: item.id)

      request_data = FolioClient::CirculationRequest.new(
        request_level: 'Item',
        request_type: item.best_request_type,
        instance_id: request.bib_data.instance_id,
        item_id: item.id,
        holdings_record_id: item.holdings_record_id,
        requester_id: patron_or_proxy_id,
        fulfillment_preference: 'Hold Shelf',
        pickup_service_point_id: pickup_location_id,
        patron_comments: request_comments,
        request_expiration_date: expiration_date
      )
      response = folio_client.create_circulation_request(request_data)

      { barcode:, msgcode: '209', response: }
    rescue FolioClient::Error => e
      Honeybadger.notify(e, error_message: "Circulation item request failed for barcode #{barcode} with #{e}")
      { barcode:, msgcode: '422', response:, errors: e.errors }
    rescue StandardError => e
      Honeybadger.notify(e, error_message: "Circulation item request failed for barcode #{barcode} with #{e}")
      { barcode:, msgcode: '456', response: }
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    def place_title_hold
      instance_id = request.bib_data.instance_id
      logger.info(
        "Submitting title hold request for user #{patron.id} and instance #{instance_id} for pickup up at #{pickup_location_id}"
      )
      { requested_items: [
        {
          barcode: instance_id,
          msgcode: '209',
          response: folio_client.create_instance_hold(patron_or_proxy_id, instance_id, hold_request)
        }
      ] }
    end

    def pickup_location_id
      @pickup_location_id ||= begin
        # Check if comparable service point code exists
        service_point = Folio::Types.service_points.find_by(code: request.destination)

        (service_point || default_service_point).id
      end
    end

    def default_service_point
      @default_service_point ||= Folio::Types.service_points.find_by(code: Settings.folio.default_service_point)
    end

    def place_item_hold(item_id:)
      logger.info(
        "Submitting item hold request for user #{patron.id} and item #{item_id} for pickup up at #{pickup_location_id}"
      )

      folio_client.create_item_hold(patron_or_proxy_id, item_id, hold_request)
    end

    def hold_request
      FolioClient::HoldRequest.new(pickup_location_id:,
                                   patron_comments: request_comments,
                                   expiration_date:)
    end

    def patron_or_proxy_id
      request.proxy? && patron.proxy? ? patron.proxy_sponsor_user_id : patron.id
    end

    def create_log(barcode:, item_id:)
      request.folio_command_logs.create!(barcode:, user_id: patron.id, item_id:, pickup_location_id:,
                                         patron_comments: request_comments, expiration_date:)
    end

    def expiration_date
      @expiration_date ||= (request.needed_date || (Time.zone.today + 3.years)).to_time.utc.iso8601
    end

    def request_comments
      [patron_comment,
       ("(PROXY PICKUP OK; request placed by #{patron.display_name} <#{patron.email}>)" if request.proxy?)].compact.join("\n")
    end

    def patron_comment
      return if user.patron&.make_request_as_patron? && !request.is_a?(Scan)

      "#{user.name} <#{user.email}>"
    end

    def patron
      @patron ||= case request
                  when Scan
                    Folio::Patron.find_by(univ_id: scan_destination.patron_barcode)
                  when Page, MediatedPage, HoldRecall
                    if user.patron&.make_request_as_patron?
                      user.patron
                    else
                      find_hold_pseudo_patron_for(request.destination_library_code)
                    end
                  end
    end

    def find_hold_pseudo_patron_for(key)
      pseudopatron_barcode = Settings.libraries[key]&.hold_pseudopatron || raise("no hold pseudopatron for '#{key}'")

      Folio::Patron.find_by(univ_id: pseudopatron_barcode)
    end

    def barcodes
      return request.barcodes unless @barcode

      request.barcodes.select do |barcode|
        @barcode == barcode
      end
    end
  end

  def self.command
    Command
  end
end
