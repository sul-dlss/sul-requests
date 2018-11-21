# frozen_string_literal: true

###
#  Helpers method for CanCan authorization in views
###
module AuthorizationHelper
  def mediated_locations_for(locations)
    locations.select do |location|
      can? :manage, Request.new(origin: location).library_location
    end
  end
end
