# frozen_string_literal: true

##
# A helper for mediation specific methods
module MediationHelper
  def current_location_for_mediated_item(item)
    current_location = Symphony::CatalogInfo.find(item.barcode).current_location
    return '' if item.home_location == current_location

    current_location
  end
end
