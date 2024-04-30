# frozen_string_literal: true

module Folio
  Location = Data.define(:id, :campus, :campus_id, :library, :library_id, :institution, :code, :discovery_display_name,
                         :name, :primary_service_point_id, :details) do
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
    def self.from_hash(dyn)
      new(
        id: dyn.fetch('id'),
        campus: (Campus.new(**dyn.fetch('campus').slice('id', 'code')) if dyn['campus']),
        campus_id: dyn['campusId'],
        library: (Library.new(**dyn.fetch('library').slice('id', 'code', 'name').symbolize_keys) if dyn['library']),
        library_id: dyn['libraryId'] || dyn.dig('library', 'id'),
        institution: (Institution.new(id: dyn.fetch('institutionId')) if dyn['institutionId']),
        code: dyn.fetch('code'),
        discovery_display_name: dyn['discoveryDisplayName'] || dyn['name'] || dyn.fetch('id'),
        name: dyn['name'],
        details: dyn['details'] || {},
        primary_service_point_id: dyn['primaryServicePoint'] # present in every location in json, but not from Graphql
      )
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity

    def campus
      to_h[:campus] || Folio::Types.campuses.find { |c| c.id == campus_id }
    end

    def library
      to_h[:library] || Folio::Types.libraries.find_by(id: library_id)
    end
  end
end
