# frozen_string_literal: true

##
# A helper for mediation specific methods
module MediationHelper
  def current_location_for_mediated_item(item)
    return '' if item.home_location == item.current_location

    item.current_location
  end
end
