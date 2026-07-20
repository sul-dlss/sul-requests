# frozen_string_literal: true

# Helper module for Requests locations
module RequestsLocationHelper
  ##
  # Generates the options needed to change a request's location
  def request_location_options(request, patron)
    options_for_select(
      eligible_service_points(request, patron).map { |sp| [sp.name, sp.id] },
      # the second param here pre-selects the current service point in the dropdown
      selected: request.service_point_id
    )
  end

  # Generates a list of service point options for a request.
  #
  # @param request [Folio::Request] The request object
  # @param patron [Folio::Patron] The patron object
  # @return [Array<Folio::ServicePoint>]
  def eligible_service_points(request, patron)
    FolioRequestServicePointOptionsService.new([request.folio_item],
                                               selected_service_point_id: request.service_point_id,
                                               patron:).possible_service_points
  end
end
