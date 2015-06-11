###
#  Controller to handle particular behaviors for HoldRecall type requests
###
class HoldRecallsController < RequestsController
  def current_request
    @hold_recall ||= HoldRecall.new
  end

  protected

  def validate_request_type
    fail NotHoldRecallableError unless @hold_recall.hold_recallable?
  end

  class NotHoldRecallableError < StandardError
  end
end
