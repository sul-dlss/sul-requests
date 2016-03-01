###
#  Controller to handle particular behaviors for MediatedPage type requests
###
class MediatedPagesController < RequestsController
  before_action :check_if_proxy_sponsor, only: :create

  protected

  def send_confirmation
    current_request.send_confirmation!
  end

  def validate_request_type
    raise UnmediateableItemError unless current_request.mediateable?
  end

  class UnmediateableItemError < StandardError
  end
end
