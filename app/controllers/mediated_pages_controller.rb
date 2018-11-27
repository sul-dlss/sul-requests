# frozen_string_literal: true

###
#  Controller to handle particular behaviors for MediatedPage type requests
###
class MediatedPagesController < RequestsController
  before_action :check_if_proxy_sponsor, only: :create

  def update
    respond_to do |format|
      if current_request.update(update_params)
        format.js { render json: current_request }
      else
        format.js { render json: { status: :error }, status: :bad_request }
      end
    end
  end

  protected

  def update_params
    params.require(:mediated_page).permit(:approval_status, :needed_date)
  end

  def send_confirmation
    current_request.send_confirmation!
  end

  def validate_request_type
    raise UnmediateableItemError unless current_request.mediateable?
  end

  class UnmediateableItemError < StandardError
  end
end
