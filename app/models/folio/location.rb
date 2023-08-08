# frozen_string_literal: true

module Folio
  Location = Data.define(:id, :campus, :library, :institution, :code, :discovery_display_name, :name, :details) do
    # rubocop:disable Metrics/AbcSize
    def self.from_hash(dyn)
      new(
        id: dyn.fetch('id'),
        campus: (Campus.new(**dyn.fetch('campus')) if dyn['campus']),
        library: (Library.new(**dyn.fetch('library')) if dyn['library']),
        institution: (Institution.new(id: dyn.fetch('institutionId')) if dyn['institutionId']),
        code: dyn.fetch('code'),
        discovery_display_name: dyn['discoveryDisplayName'] || dyn['name'] || dyn.fetch('id'),
        name: dyn['name'],
        details: dyn.fetch('details', {})
      )
    end
    # rubocop:enable Metrics/AbcSize
  end
  Library = Data.define(:id, :code)
  Campus = Data.define(:id, :code)
  Institution = Data.define(:id)
end
