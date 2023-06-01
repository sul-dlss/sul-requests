# frozen_string_literal: true

##
# A helper for mediation specific methods
module MediationHelper
  def current_location_for_mediated_item(item)
    if Settings.ils.bib_model == 'Folio::BibData'
      item.temporary_location.to_s
    else
      current_location = Symphony::CatalogInfo.find(item.barcode).current_location
      item.home_location == current_location ? '' : current_location
    end
  end
end
