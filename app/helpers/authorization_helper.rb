# frozen_string_literal: true

###
#  Helpers method for CanCan authorization in views
###
module AuthorizationHelper
  def mediateable_origins
    mediateable_locations = PatronRequest.accessible_by(current_ability, :mediate).select(:origin_location_code).distinct
    folio_locations = Folio::Types.locations.all.index_by(&:code)

    mediateable_locations.group_by do |location_code|
      library_code = folio_locations[location_code]&.library&.code
      if Settings.admin_locations[location_code]
        LibraryLocation.new(library_code, location_code)
      else
        LibraryLocation.new(library_code)
      end
    end.keys
  end
end
