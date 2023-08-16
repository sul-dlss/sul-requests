# frozen_string_literal: true

module Folio
  # Models a location from Folio
  class Location
    # rubocop:disable Metrics/ParameterLists
    def initialize(id:, campus_id:, library_id:, institution_id:, code:, discovery_display_name:,
                   name:, primary_service_point_id:, details:)
      @id = id
      @library_id = library_id
      @campus_id = campus_id
      @institution_id = institution_id
      @code = code
      @discovery_display_name = discovery_display_name
      @name = name
      @primary_service_point_id = primary_service_point_id
      @details = details
    end
    # rubocop:enable Metrics/ParameterLists

    attr_reader :id, :campus_id, :library_id, :institution_id, :code, :discovery_display_name, :name, :primary_service_point_id, :details

    def self.from_hash(dyn)
      new(
        id: dyn.fetch('id'),
        campus_id: dyn.fetch('campusId'),
        library_id: dyn['libraryId'] || dyn.dig('library', 'id'),
        institution_id: dyn.fetch('institutionId'),
        code: dyn.fetch('code'),
        discovery_display_name: dyn['discoveryDisplayName'] || dyn['name'] || dyn.fetch('id'),
        name: dyn['name'],
        details: dyn.fetch('details', {}),
        primary_service_point_id: dyn['primaryServicePoint'] # present in every location in json, but not from Graphql
      )
    end

    def library
      @library ||= Folio::Types.libraries.find_by(id: library_id)
    end

    def campus
      @campus ||= Folio::Types.campuses.find_by(id: campus_id)
    end
  end
end
