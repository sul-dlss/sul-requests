# frozen_string_literal: true

###
#  Class to handle configuration and logic around library codes and labels
###
class RequestLocation
  attr_reader :location

  def initialize(location)
    @location = location
  end

  def library
    @library ||= FolioLocationMap.library_code(location:)
  end

  def active_messages
    @active_messages ||= Message.where(library: [library, 'anywhere']).active
  end

  def library_name
    Folio::Types.libraries.find_by(code: library)&.name
  end

  def library_settings
    Settings.libraries[library]
  end
end
