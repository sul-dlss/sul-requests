# frozen_string_literal: true

module Folio
  # ? FOLIO: Request = "Hold" in Folio - consider renaming for clarity
  class Request
    include Folio::FolioRecord

    attr_reader :record

    # A sufficiently large time used to sort nil values last
    END_OF_DAYS = 100.years.from_now # rubocop:disable Rails/RelativeDateConstant

    def initialize(record)
      @record = record
    end

    def key
      record['requestId']
    end

    def patron_key
      record.dig('details', 'proxyUserId') || record.dig('details', 'requesterId')
    end

    # @return [Boolean] Returns true if the proxyUserId exists
    def proxy_request?
      record.dig('details', 'proxyUserId').present?
    end

    def status
      record['status']
    end

    def ready_for_pickup?
      status == 'Open___Awaiting_pickup'
    end

    def queue_position
      record['queuePosition']
    end

    def queue_length
      record['queueTotalLength']
    end

    def expiration_date
      Time.zone.parse(record.dig('details', 'holdShelfExpirationDate')) if record.dig('details',
                                                                                      'holdShelfExpirationDate')
    end

    def placed_date
      Time.zone.parse(record['requestDate']) if record['requestDate']
    end

    def fill_by_date
      Time.zone.parse(record['expirationDate']) if record['expirationDate']
    end

    def waitlist_position
      return 'Unknown' if queue_position.nil? && queue_length.nil?

      "#{queue_position} of #{queue_length}"
    end

    def active?
      status.start_with?('Open')
    end

    def item_call_key
      item&.dig('effectiveCallNumberComponents', 'callNumber')
    end

    def contact_info
      location&.contact_info
    end

    def service_point_name
      Folio::Types.service_points.find_by(id: service_point_id)&.name || service_point_code
    end

    def service_point_code
      record.dig('pickupLocation', 'code')
    end

    def service_point_id
      record['pickupLocationId']
    end

    def restricted_pickup_service_points
      service_points = item&.dig('effectiveLocation', 'details', 'pageServicePoints') || []

      @restricted_pickup_service_points ||= service_points.map do |service_point|
        Folio::ServicePoint.from_dynamic(service_point)
      end
    end

    # rubocop:disable Metrics/MethodLength
    def sort_key(key)
      sort_key = case key
                 when :library
                   [service_point_code, title, author, shelf_key]
                 when :date
                   [*date_sort_key, title, author, shelf_key]
                 when :title
                   [title, author, shelf_key]
                 when :author
                   [author, title, shelf_key]
                 when :call_number
                   [shelf_key]
                 end

      sort_key.join('---')
    end
    # rubocop:enable Metrics/MethodLength

    def date_sort_key
      [
        (expiration_date || END_OF_DAYS).strftime('%FT%T'),
        (fill_by_date || END_OF_DAYS).strftime('%FT%T')
      ]
    end

    def manage_request_link; end
  end
end
