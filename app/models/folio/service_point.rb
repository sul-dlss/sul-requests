# frozen_string_literal: true

module Folio
  # A place where FOLIO items can be serviced (e.g. a pickup location)
  class ServicePoint
    attr_reader :id, :code, :name, :pickup_location, :is_default_pickup, :is_default_for_campus

    # rubocop:disable Metrics/ParameterLists
    def initialize(id:, code:, name:, is_default_pickup:, is_default_for_campus:, pickup_location: false)
      @id = id
      @code = code
      @name = name
      @pickup_location = pickup_location
      @is_default_pickup = is_default_pickup
      @is_default_for_campus = is_default_for_campus
    end
    # rubocop:enable Metrics/ParameterLists

    def self.from_dynamic(json)
      new(id: json.fetch('id'),
          code: json.fetch('code'),
          name: json.fetch('discoveryDisplayName'),
          pickup_location: json.fetch('pickupLocation', false),
          is_default_pickup: json.dig('details', 'isDefaultPickup'),
          is_default_for_campus: json.dig('details', 'isDefaultForCampus'))
    end

    def unpermitted_pickup_groups
      Array(Settings.libraries[library&.code]&.unpermitted_pickup_groups)
    end

    def library
      return if library_id.nil?

      if defined?(@library)
        @library
      else
        @library = Folio::Types.libraries.find_by(id: library_id)
      end
    end

    def pickup_location?
      pickup_location == true
    end

    private

    def library_id
      # Not every service point, e.g .RWC, has an associated location or library
      @library_id ||= Folio::Types.locations.find_by(primary_service_point_id: id)&.library_id
    end
  end
end
