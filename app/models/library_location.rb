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

  def pickup_libraries
    case
    when location_specific_pickup_library_config.present?
      location_specific_pickup_libraries
    when library_specific_pickup_library_config.present?
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
    pickup_libraries_for(library_specific_pickup_library_config)
  end

  def location_specific_pickup_libraries
    pickup_libraries_for(location_specific_pickup_library_config)
  end

  def library_specific_pickup_library_config
    config.library_specific_pickup_libraries[@library]
  end

  def location_specific_pickup_library_config
    config.location_specific_pickup_libraries[@location] ||
      config.location_specific_pickup_libraries.dig(@library, @location)
  end
end
