# frozen_string_literal: true

module Folio
  # Encapsulates pickup destination logic for FOLIO service points
  class PickupDestination
    # Get the default destination
    def self.default_destination
      Settings.folio.default_service_point
    end

    # @param destination_code: service point code
    def initialize(destination_code)
      @code = destination_code
    end

    attr_reader :code

    def display_label
      Folio::Types.service_points.find_by(code:).name
    end

    # For paging scheduling, we must map from service point to library if folio
    # Otherwise, the library code is what we will be receiving
    def library_code
      Folio::Types.map_to_library_code(code)
    end
  end
end
