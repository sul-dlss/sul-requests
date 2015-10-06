###
#  Controller to handle particular behaviors for MediatedPage type requests
###
class MediatedPagesController < RequestsController
  protected

  def send_confirmation
    current_request.send_confirmation!
  end

  def validate_request_type
    fail UnmediateableItemError unless current_request.mediateable?
  end

  class UnmediateableItemError < StandardError
  end
end
