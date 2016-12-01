###
#  Class to handle configuration and logic around library codes and labels
###
class LibraryLocation
  attr_reader :request, :library, :location

  include HoldRecallable
  include Mediateable
  include Scannable

  def initialize(request)
    @request = request
    @library = request.origin
    @location = request.origin_location
  end

  def pageable?
    !mediateable? && !hold_recallable?
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

  def mhld
    request.holdings_object.mhld
  end

  class << self
    def library_name_by_code(code)
      all_libraries[code] || location_specific_library_name_by_code(code)
    end

    def location_specific_library_name_by_code(code)
      pickup_libraries_for_location = Array(config.location_specific_pickup_libraries[code])
      return unless pickup_libraries_for_location.one?
      all_libraries[pickup_libraries_for_location.first]
    end

    def config
      SULRequests::Application.config
    end

    def all_libraries
      config.libraries
    end

    def pageable_libraries
      all_libraries.select { |k, _| config.pageable_libraries.include? k }
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
    end.merge(additional_pickup_libraries)
  end

  def additional_pickup_libraries
    return {} unless SULRequests::Application.config.include_self_in_library_list.include?(@library)
    all_libraries.select { |k, _| k == @library }
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
