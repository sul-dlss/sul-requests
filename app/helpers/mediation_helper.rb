# frozen_string_literal: true

##
# A helper for mediation specific methods
module MediationHelper
  def current_location_for_mediated_item(item)
    return '' if item.permanent_location&.code == item.temporary_location&.code

    item.temporary_location&.name
  end
end
