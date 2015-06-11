###
#  Controller to handle particular behaviors for HoldRecall type requests
###
class HoldRecallsController < RequestsController
  protected

  def validate_request_type
    fail NotHoldRecallableError unless current_request.hold_recallable?
  end

  class NotHoldRecallableError < StandardError
  end
end
