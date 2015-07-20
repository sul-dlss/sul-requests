###
#  Mixin to encapsulate defining hold recall requests
###
module HoldRecallable
  def hold_recallable?
    barcode_present? || on_order? || in_process?
  end

  private

  def barcode_present?
    @request.requested_barcode.present?
  end

  def on_order?
    [current_location, origin_location].include?('ON-ORDER')
  end

  def in_process?
    [current_location, origin_location].include?('INPROCESS')
  end

  def current_location
    @request.holdings.first.try(:current_location).try(:code)
  end

  def origin_location
    @request.origin_location
  end
end
