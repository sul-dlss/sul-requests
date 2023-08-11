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
    Honeybadger.notify('Unable to find Request', conext: { request_id: })
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
        item_id = folio_client.get_item(barcode)['id']
        create_log(barcode:, item_id:)
        response = place_item_hold(item_id:)
        { barcode:, msgcode: '209', response: }
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
        code = service_point_code(request.destination)
        Folio::Types.service_points.find_by(code:)&.id
      end
    end

    def service_point_code(destination)
      # Check if comparable service point code exists, otherwise return default
      return destination if Folio::Types.service_points.find_by(code: destination)

      # During cutover and migration, we may still need to depend on the service point defined in settings
      Settings.libraries[destination]&.folio_pickup_service_point_code || Settings.folio.default_service_point
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
      @expiration_date ||= ((request.needed_date unless request.is_a?(Page)) || (Time.zone.today + 3.years)).to_time.utc.iso8601
    end

    def request_comments
      [patron.patron_comments,
       ("(PROXY PICKUP OK; request placed by #{patron.display_name} <#{patron.email}>)" if request.proxy?)].compact.join("\n")
    end

    # rubocop:disable Metrics/MethodLength
    def patron
      @patron ||= case request
                  when Scan
                    build_pseudopatron(scan_destination.folio_pseudopatron)
                  when HoldRecall
                    user.patron
                  when Page, MediatedPage
                    if user.patron&.make_request_as_patron?
                      user.patron
                    else
                      find_hold_pseudo_patron_for(request.destination)
                    end
                  end
    end
    # rubocop:enable Metrics/MethodLength

    def build_pseudopatron(id)
      PsuedoPatron.new(id:, patron_comments: "#{user.name} <#{user.email}>")
    end

    def find_hold_pseudo_patron_for(key)
      key = Folio::Types.instance.map_to_library_code(key)
      id = Settings.libraries[key]&.folio_hold_pseudopatron || raise("no hold pseudopatron for '#{key}'")
      build_pseudopatron(id)
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
