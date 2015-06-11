###
#  Controller to handle particular behaviors for MediatedPage type requests
###
class MediatedPagesController < RequestsController
  protected

  def validate_request_type
    fail UnmediateableItemError unless current_request.mediateable?
  end

  class UnmediateableItemError < StandardError
  end
end
