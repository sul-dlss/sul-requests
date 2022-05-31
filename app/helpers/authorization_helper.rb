# frozen_string_literal: true

###
#  Helpers method for CanCan authorization in views
###
module AuthorizationHelper
  def mediated_locations_for(locations)
    locations.select do |code, config|
      library_location = if config.library_override
                           LibraryLocation.new(config.library_override, code.to_s)
                         else
                           LibraryLocation.new(code.to_s)
                         end

      can? :manage, library_location
    end
  end
end
