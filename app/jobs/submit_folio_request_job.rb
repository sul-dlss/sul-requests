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
    response = Command.new(request, **options).execute!

    Sidekiq.logger.debug("FOLIO response: #{response}")
    request.merge_ils_response_data(FolioResponse.new(response.with_indifferent_access))
    request.save
    request.send_approval_status!
    Sidekiq.logger.info("Completed SubmitFolioRequestJob for request #{request_id}")
  end

  def find_request(request_id)
    Request.find(request_id)
  rescue ActiveRecord::RecordNotFound
    Honeybadger.notify('Unable to find Request', conext: { request_id: request_id })
  end

  # Submit a hold request to FOLIO
  class Command
    attr_reader :request, :folio_client, :barcode

    delegate :user, to: :request
    delegate :patron, to: :user

    def initialize(request, folio_client: nil, barcode: nil)
      @request = request
      @folio_client = folio_client || FolioClient.new
      @barcode = barcode
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def execute!
      responses = barcodes.map do |barcode|
        user_id = request.user.patron.id
        item_id = folio_client.get_item(barcode)['id']

        code = Settings.libraries[request.destination].folio_pickup_service_point_code
        pickup_location_id = folio_client.get_service_point(code)['id']

        Rails.logger.info(
          "Submitting hold request for user #{user_id} and item #{item_id} for pickup up at #{code} (#{pickup_location_id})"
        )

        expiration_date = (request.needed_date || Time.zone.today + 3.years).utc.iso8601

        place_hold_response = folio_client.create_item_hold(user_id, item_id, pickupLocationId: pickup_location_id,
                                                                              patronComments: request.item_comment,
                                                                              expirationDate: expiration_date)

        {
          barcode: barcode,
          msgcode: '209',
          response: place_hold_response
        }
      end

      {
        requested_items: responses
      }
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    def request_params
      {}
    end

    private

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
