###
#  Mixin to encapsulate defining hold recall requests
###
module HoldRecallable
  def hold_recallable?
    @request.requested_barcode.present?
  end
end
