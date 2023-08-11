# frozen_string_literal: true

module Folio
  # Encapsulates pickup destination logic for FOLIO service points
  class PickupDestination
    include Folio::TypesUtils

    # Get the default destination
    def self.default_destination
      Settings.folio.default_service_point
    end

    # @param code: service point or library code
    def initialize(destination_code)
      @code = destination_code
      @type = 'ServicePoint'
    end

    def display_label
      get_service_point_name(@code)
    end

    # For paging scheduling, we must map from service point to library if folio
    # Otherwise, the library code is what we will be receiving
    def paging_code
      map_to_library(@code)
    end
  end
end
