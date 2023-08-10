# frozen_string_literal: true

module Folio
  # Encapsulates pickup destination logic for FOLIO service points OR libraries for Symphony
  class Destination
    include Folio::TypesUtils

    # Get the default destination
    def self.default_destination
      folio? ? Settings.folio.default_service_point : Settings.default_pickup_library
    end

    # @param code: service point or library code
    def initialize(destination_code)
      @code = destination_code
      @type = self.class.folio? ? 'ServicePoint' : 'Library'
    end

    def display_label
      # If FOLIO, get the service point name
      return get_service_point_name(@code) if service_point?

      # If not FOLIO
      Settings.libraries[@code]&.label
    end

    # For paging scheduling, we must map from service point to library if folio
    # Otherwise, the library code is what we will be receiving
    def paging_code
      return map_to_library(@code) if service_point?

      @code
    end

    def service_point?
      @type == 'ServicePoint'
    end

    def library?
      @type == 'Library'
    end

    def self.folio?
      Settings.ils == Settings.folio_ils
    end
  end
end
