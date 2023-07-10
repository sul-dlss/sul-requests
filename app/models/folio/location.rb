module Folio
  Location = Data.define(:id, :campus, :library, :institution, :code, :discovery_display_name, :name, :details) do
    def self.from_hash(dyn)
      new(
        id: dyn.fetch('id'),
        campus: Campus.new(id: dyn.fetch('campusId')),
        library: Library.new(id: dyn.fetch('libraryId')),
        institution: Institution.new(id: dyn.fetch('institutionId')),
        code: dyn.fetch('code'),
        discovery_display_name: dyn.fetch('discoveryDisplayName') || dyn.fetch('name'),
        name: dyn.fetch('name'),
        details: dyn.fetch('details', {}) || {}
      )
    end
  end
  Library = Data.define(:id)
  Campus = Data.define(:id)
  Institution = Data.define(:id)
end
