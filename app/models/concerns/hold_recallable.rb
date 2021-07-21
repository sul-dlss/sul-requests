# frozen_string_literal: true

###
#  Mixin to encapsulate defining hold recall requests
###
module HoldRecallable
  # returns a true if any of the following is true
  #   - The incoming request includes a barcode (which means an item-level link, likely a checked out item)
  #   - The home location or current location is an allowed recallable location by Settings.hold_recallable
  #   - There is only a single item to be requested and it is checked out
  def hold_recallable?
    return false unless Settings.features.hold_recall_service

    @request.barcode_present? ||
      hold_recallable_location? ||
      single_checked_out_item?
  end

  private

  def hold_recallable_location?
    hold_recallable_rules.applies_to(self).any?
  end

  def hold_recallable_rules
    LocationRules.new(Settings.hold_recallable)
  end

  def single_checked_out_item?
    @request.holdings_object.single_checked_out_item?
  end
end
