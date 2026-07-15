# frozen_string_literal: true

###
#  Class to handle configuration and logic around library codes and labels
###
class LibraryLocation
  attr_reader :library_code, :location_code

  def initialize(library_code, location_code = nil)
    @library_code = library_code
    @location_code = location_code
  end

  def active_messages
    @active_messages ||= Message.where(library: [library_code, 'anywhere']).active
  end

  def library_name
    library&.name(fallback_value: nil) || Settings.libraries[library_code]&.label || library_code
  end

  def location_name
    location&.name || location_code
  end

  def library
    return @library if defined?(@library)
    return location.library if location

    @library = Folio::Types.libraries.find_by(code: library_code)
  end

  def location
    return unless location_code
    return @location if defined?(@location)

    @location = Folio::Types.locations.find_by(code: location_code)
  end

  class << self
    def library_name_by_code(code)
      LibraryLocation.new(code).library_name
    end
  end
end
