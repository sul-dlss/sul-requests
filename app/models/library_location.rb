###
#  Class to handle configuration and logic around library codes and labels
###
class LibraryLocation
  attr_reader :library, :location

  include Scannable
  include Mediateable

  def initialize(request)
    @library = request.origin
    @location = request.origin_location
  end

  def pageable?
    !mediateable?
  end

  def pickup_libraries
    case
    when location_specific_pickup_libraries?
      location_specific_pickup_libraries
    when library_specific_pickup_libraries?
      library_specific_pickup_libraries
    else
      pickup_libraries_for(config.pickup_libraries)
    end
  end

  def active_messages
    @active_messages ||= Message.where(library: [library, 'anywhere']).active
  end

  class << self
    def library_name_by_code(code)
      config.libraries[code]
    end

    def config
      SULRequests::Application.config
    end

    def all_libraries
      config.libraries
    end
  end

  private

  def all_libraries
    self.class.all_libraries
  end

  def config
    self.class.config
  end

  def pickup_libraries_for(collection)
    all_libraries.select do |k, _|
      collection.include?(k)
    end
  end

  def library_specific_pickup_libraries
    pickup_libraries_for(config.library_specific_pickup_libraries[@library])
  end

  def location_specific_pickup_libraries
    pickup_libraries_for(config.location_specific_pickup_libraries[@location])
  end

  def library_specific_pickup_libraries?
    config.library_specific_pickup_libraries.keys.include?(@library)
  end

  def location_specific_pickup_libraries?
    config.location_specific_pickup_libraries.keys.include?(@location)
  end
end
