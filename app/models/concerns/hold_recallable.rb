###
#  Mixin to encapsulate defining hold recall requests
###
module HoldRecallable
  LOCATIONS = %w(INPROCESS ON-ORDER).freeze

  # returns a true if any of the following is true
  #   - The incoming request includes a barcode (which means an item-level link, likely a checked out item)
  #   - The home location OR ALL current locations are in the HoldRecallable::LOCATIONS
  #   - ALL current locations are MISSING (this might be able to just go in the HoldRecallable::LOCATIONS array)
  #   - There is only a single item to be requested and it is checked out
  def hold_recallable?
    @request.barcode_present? ||
      hold_recallable_current_or_home_location? ||
      missing_current_location? ||
      single_checked_out_item?
  end

  private

  def hold_recallable_current_or_home_location?
    return true if LOCATIONS.include?(origin_location)

    current_locations_are_all?(LOCATIONS)
  end

  def missing_current_location?
    current_locations_are_all?('MISSING')
  end

  def current_locations_are_all?(current_location)
    current_locations = Array.wrap(current_location)

    @request.holdings.present? && @request.holdings.all? do |holding|
      current_locations.include?(holding.try(:current_location).try(:code))
    end
  end

  def origin_location
    @request.origin_location
  end

  def single_checked_out_item?
    @request.holdings_object.single_checked_out_item?
  end
end
