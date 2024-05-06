# frozen_string_literal: true

###
#  Controller to handle particular behaviors for MediatedPage type requests
###
class MediatedPagesController < RequestsController
  def update
    respond_to do |format|
      if current_request.update(update_params)
        format.json { render json: current_request }
      else
        format.json { render json: { status: :error }, status: :bad_request }
      end
    end
  end

  protected

  def update_params
    params.require(:request).permit(:approval_status)
  end

  def validate_request_type
    raise UnmediateableItemError unless current_request.mediateable?
  end

  class UnmediateableItemError < StandardError
  end
end
