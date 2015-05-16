###
#  Controller for returning the pageing schedule for async requests
###
class PagingScheduleController < ApplicationController
  def show
    estimate = PagingSchedule.for(request_for_schedule).estimate
    respond_to do |format|
      format.json { render json: estimate }
      format.html { render text: estimate.to_s, layout: false }
    end
  end

  def index
    authorize! :manage, PagingSchedule
    @paging_schedule = PagingSchedule.schedule
  end

  private

  def request_for_schedule
    Request.new(
      origin: params[:origin],
      destination: params[:destination]
    )
  end
end
