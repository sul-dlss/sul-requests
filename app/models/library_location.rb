# frozen_string_literal: true

###
#  Class to handle configuration and logic around library codes and labels
###
class LibraryLocation
  attr_reader :library, :location

  def initialize(library, location)
    @library = library
    @location = location
  end

  def active_messages
    @active_messages ||= Message.where(library: [library, 'anywhere']).active
  end

  class << self
    def library_name_by_code(code)
      all_libraries[code]&.label
    end

    def all_libraries
      Settings.libraries
    end

    def pageable_libraries
      all_libraries.map.select { |_, v| v.pageable }.to_h.stringify_keys
    end
  end
end
