###
#  Controller to handle particular behaviors for HoldRecall type requests
###
class HoldRecallsController < RequestsController
  before_action :check_if_proxy_sponsor, only: :create
  before_action :set_needed_date, only: [:new, :create]

  protected

  def set_needed_date
    current_request.needed_date ||= Time.zone.today + 1.year
  end

  def validate_request_type
    raise NotHoldRecallableError unless current_request.hold_recallable?
  end

  class NotHoldRecallableError < StandardError
  end
end
