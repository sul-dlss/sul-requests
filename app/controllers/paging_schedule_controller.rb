###
#  Controller for returning the pageing schedule for async requests
###
class PagingScheduleController < ApplicationController
  def show
    schedule = PagingSchedule.for(request_for_schedule)
    return unless schedule.present?
    respond_to do |format|
      format.json { render json: schedule.estimate }
      format.html { render text: schedule.estimate.to_s, layout: false }
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
