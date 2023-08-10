# frozen_string_literal: true

module Folio
  # Map between service points and libraries and identify service points and libraries by code or id
  module TypesUtils
    # For FOLIO, destination is specified as service point
    # Convert service point to library for scheduling and library hours
    def map_to_library(service_point_code)
      return service_point_code if service_point_code == 'SCAN'

      return nil unless valid_service_point_code?(service_point_code)

      service_point_id = get_service_point_id(service_point_code)
      library_id = get_library_for_service_point(service_point_id)

      # Find the library code associated with this library id
      Folio::Types.instance.get_type('libraries').find { |library| library['id'] == library_id }['code']
    end

    # Find the service point ID based on this service point code
    def get_service_point_id(service_point_code)
      Folio::Types.instance.service_points.values.find { |v| v.code == service_point_code }&.id
    end

    # Find the library id for the location with which this service point is associated
    def get_library_for_service_point(service_point_id)
      loc = Folio::Types.instance.get_type('locations').find { |location| location['primaryServicePoint'] == service_point_id }
      loc.present? && loc.key?('libraryId') ? loc['libraryId'] : nil
    end

    # Check if valid service point
    def valid_service_point_code?(service_point_code)
      Folio::Types.instance.service_points.values.find { |v| v.code == service_point_code }.present?
    end

    # Given a library code, retrieve the primary service point, ensuring pickup location is true
    def map_to_service_point(library_code)
      # Find library id for the library with this code
      library_id = get_library_id(library_code)
      # Get the associated location and related service point
      service_point_id = get_service_point_for_library(library_id)
      # Find the service point ID based on this service point code
      service_point = get_service_point_by_id(service_point_id)
      service_point.present? && service_point.pickup_location == true ? service_point.code : nil
    end

    def get_library_id(library_code)
      lib = Folio::Types.instance.get_type('libraries').find { |library| library['code'] == library_code }
      lib.present? && lib.key?('id') ? lib['id'] : nil
    end

    def get_service_point_for_library(library_id)
      loc = Folio::Types.instance.get_type('locations').find { |location| location['libraryId'] == library_id }
      loc.present? && loc.key?('primaryServicePoint') ? loc['primaryServicePoint'] : nil
    end

    def get_service_point_by_id(service_point_id)
      Folio::Types.instance.service_points.values.find { |v| v.id == service_point_id }
    end

    # Get the name for the service point given the code
    def get_service_point_name(code)
      # Find the service point with the same code, and return the name
      Folio::Types.instance.service_points.values.find { |v| v.code == code }&.name
    end
  end
end
