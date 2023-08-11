# frozen_string_literal: true

module Folio
  # A place where FOLIO items can be serviced (e.g. a pickup location)
  ServicePoint = Data.define(:id, :code, :name, :pickup_location, :is_default_pickup, :is_default_for_campus) do
    def self.from_dynamic(json)
      new(id: json.fetch('id'),
          code: json.fetch('code'),
          name: json.fetch('discoveryDisplayName'),
          pickup_location: json.fetch('pickupLocation', false),
          is_default_pickup: json.dig('details', 'isDefaultPickup'),
          is_default_for_campus: json.dig('details', 'isDefaultForCampus'))
    end

    def pickup_location?
      pickup_location == true
    end
  end
end
