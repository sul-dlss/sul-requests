# frozen_string_literal: true

###
#  Helpers method for CanCan authorization in views
###
module AuthorizationHelper
  def mediated_locations_for(locations)
    locations.select do |code, config|
      request = if config.library_override
                  Request.new(origin: config.library_override, origin_location: code.to_s)
                else
                  Request.new(origin: code.to_s)
                end

      can? :manage, request.library_location
    end
  end
end
