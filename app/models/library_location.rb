# frozen_string_literal: true

###
#  Class to handle configuration and logic around library codes and labels
###
class LibraryLocation
  attr_reader :library, :location

  def initialize(library, location = nil)
    @library = library
    @location = location
  end

  def active_messages
    @active_messages ||= Message.where(library: [library, 'anywhere']).active
  end

  # This is the code Folio uses, which is a combination of library & Symphony location
  def folio_location_code
    @folio_location_code ||= FolioLocationMap.folio_code_for(library_code: library, home_location: location)
  rescue FolioLocationMap::NotFound
    Honeybadger.notify('Location code not found', context: { library:, location: })
    nil
  end

  class << self
    # Most library codes used in requests will be FOLIO codes
    # Settings will be used for the RWC code which has a service point but no FOLIO library associated
    def library_name_by_code(code)
      Folio::Types.libraries.find_by(code:)&.name || Settings.libraries[code]&.label
    end

    # This is a super-clunky way to convert data from RailsConfig to something
    # Enumerable, so we can use e.g. #select
    def all_settings_libraries
      Settings.libraries.map.to_h.with_indifferent_access
    end

    def pageable_libraries
      all_settings_libraries.select { |_, v| v.pageable }
    end
  end
end
