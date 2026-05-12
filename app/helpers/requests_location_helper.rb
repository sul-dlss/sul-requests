# frozen_string_literal: true

# Helper module for Requests locations
module RequestsLocationHelper
  ##
  # Generates the options needed to change a request's location
  def request_location_options(request, patron)
    options_for_select(
      service_points(request, patron),
      # the second param here pre-selects the current service point in the dropdown
      selected: request.service_point_id
    )
  end

  # Generates a list of service point options for a request.
  #
  # @param request [Request] The request object
  # @return [Array<Array<String, String>>] Array of service points in [label, value] format for options_for_select
  def service_points(request, patron)
    return restricted_service_point_options(request, patron) if request.restricted_pickup_service_points.present?

    service_point_options(request, patron)
  end

  private

  # Returns an array of service point options in the format for options_for_select: [[label1, value1], [label2, value2]]
  #
  # @param request [Request] The request object
  # @return [Array<Array<String, String>>] An array of service point options in [label, value] format
  def restricted_service_point_options(request, patron)
    request.restricted_pickup_service_points.filter_map do |service_point|
      if service_point.patron_unpermitted_for_pickup?(patron) &&
         service_point.id != request.service_point_id # if the service point is already selected, don't take it away
        next
      end

      [service_point.name, service_point.id]
    end
  end

  # Returns an array of service point options in the format for options_for_select: [[label1, value1], [label2, value2]]
  #
  # @param request [Request] The request object
  # @return [Array<Array<String, String>>] An array of service point options in [label, value] format
  def service_point_options(request, patron)
    # start with the full list of defaults
    default_service_points = Folio::ServicePoint.default_service_points
    # Add the request's origin service point to the list
    default_service_points << Folio::Types.service_points.find_by(id: request.service_point_id)
    # Remove duplicates and nils in case origin was already in the default list or doesn't exit
    # Filter out non-pickup locations
    # Map the service points to the [label, value] format for options_for_select
    default_service_points.compact.uniq(&:id).select { |service_point| service_point.pickup_location == true }
                                             .filter_map do |service_point|
                                               if service_point.patron_unpermitted_for_pickup?(patron) &&
                                                  # ... but if the service point is already selected, don't take it away
                                                  service_point.id != request.service_point_id
                                                 next
                                               end

                                               [service_point.name, service_point.id]
                                             end
  end
end
