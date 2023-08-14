# frozen_string_literal: true

module Symphony
  # Encapsulates pickup destination logic for Symphony
  class PickupDestination
    # Get the default destination
    def self.default_destination
      Settings.default_pickup_library
    end

    # @param destination_code: library code
    def initialize(destination_code)
      @code = destination_code
    end

    def display_label
      Settings.libraries[@code]&.label
    end

    # For paging scheduling, we must map from service point to library if folio
    # Otherwise, the library code is what we will be receiving
    def paging_code
      @code
    end
  end
end
