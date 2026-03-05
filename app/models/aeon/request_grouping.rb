# frozen_string_literal: true

module Aeon
  # Wraps Aeon request records
  class RequestGrouping
    include Enumerable

    attr_reader :requests

    delegate :each, to: :requests

    delegate :shipping_option, :appointment, to: :first

    def initialize(requests)
      @requests = requests
    end

    def draft_requests
      requests.select(&:draft?)
    end

    def submitted_requests
      requests.select(&:submitted?)
    end

    def reading_room_name
      appointment&.reading_room&.name
    end

    def digitization?
      shipping_option == 'Electronic Delivery'
    end
  end
end
