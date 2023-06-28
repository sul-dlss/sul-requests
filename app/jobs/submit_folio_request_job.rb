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

    Sidekiq.logger.info("Started SubmitFolioRequestJob for request #{request_id}")
    response = Command.new(request, logger:, **options).execute!

    Sidekiq.logger.debug("FOLIO response: #{response}")
    request.merge_ils_response_data(FolioResponse.new(response.with_indifferent_access))
    request.save
    request.send_approval_status!
    Sidekiq.logger.info("Completed SubmitFolioRequestJob for request #{request_id}")
  end

  def find_request(request_id)
    Request.find(request_id)
  rescue ActiveRecord::RecordNotFound
    Honeybadger.notify('Unable to find Request', conext: { request_id: })
  end

  # Submit a hold request to FOLIO
  class Command
    attr_reader :request, :folio_client, :barcode, :logger

    delegate :user, to: :request
    delegate :patron, to: :user

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
      requested_items = barcodes.map do |barcode|
        response = request_item(user_id: patron.id, pickup_location_id:, barcode:)
        { barcode:, msgcode: '209', response: }
      end
      { requested_items: }
    end

    private

    def pickup_location_id
      @pickup_location_id ||= begin
        code = Settings.libraries[request.destination].folio_pickup_service_point_code
        folio_client.get_service_point(code)['id']
      end
    end

    def request_item(user_id:, pickup_location_id:, barcode:)
      item_id = folio_client.get_item(barcode)['id']
      place_hold(item_id:, user_id:, pickup_location_id:)
    end

    def place_hold(item_id:, user_id:, pickup_location_id:)
      logger.info(
        "Submitting hold request for user #{user_id} and item #{item_id} for pickup up at #{pickup_location_id}"
      )

      expiration_date = (request.needed_date || (Time.zone.today + 3.years)).to_time.utc.iso8601
      hold_request = FolioClient::HoldRequest.new(pickup_location_id:,
                                                  patron_comments: request.item_comment,
                                                  expiration_date:)
      folio_client.create_item_hold(user_id, item_id, hold_request)
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
