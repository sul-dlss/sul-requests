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

  class << self
    def library_name_by_code(code)
      Folio::Types.libraries.find_by(code:)&.name(fallback_value: nil) || all_libraries[code]&.label
    end

    # This is a super-clunky way to convert data from RailsConfig to something
    # Enumerable, so we can use e.g. #select
    def all_libraries
      Settings.libraries.map.to_h.with_indifferent_access
    end
  end
end
