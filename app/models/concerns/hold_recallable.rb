###
#  Mixin to encapsulate defining hold recall requests
###
module HoldRecallable
  def hold_recallable?
    @request.barcode_present? ||
      on_order? ||
      in_process? ||
      missing? ||
      single_checked_out_item?
  end

  private

  def on_order?
    [current_location, origin_location].include?('ON-ORDER')
  end

  def in_process?
    [current_location, origin_location].include?('INPROCESS')
  end

  def missing?
    current_location == 'MISSING'
  end

  def current_location
    @request.holdings.first.try(:current_location).try(:code)
  end

  def origin_location
    @request.origin_location
  end

  def single_checked_out_item?
    @request.holdings_object.single_checked_out_item?
  end
end
