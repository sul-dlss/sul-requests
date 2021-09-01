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

    def config
      SULRequests::Application.config
    end

    def all_libraries
      Settings.libraries
    end

    def pageable_libraries
      all_libraries.map.select { |k, _| config.pageable_libraries.include? k.to_s }
    end
  end
end
