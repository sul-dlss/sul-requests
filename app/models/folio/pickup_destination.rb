# frozen_string_literal: true

module Folio
  # Encapsulates pickup destination logic for FOLIO service points
  class PickupDestination
    # Get the default destination
    def self.default_destination
      Settings.folio.default_service_point
    end

    attr_reader :code

    # @param destination_code: service point code
    def initialize(destination_code)
      @code = destination_code
    end

    def service_point
      @service_point ||= Folio::Types.service_points.find_by(code:)
    end

    def display_label
      service_point&.name
    end

    # For paging scheduling, we must map from service point to library if folio
    # Otherwise, the library code is what we will be receiving
    def library_code
      service_point&.library&.code
    end
  end
end
