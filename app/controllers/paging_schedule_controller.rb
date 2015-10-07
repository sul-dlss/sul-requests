###
#  Controller for returning the pageing schedule for async requests
###
class PagingScheduleController < ApplicationController
  rescue_from PagingSchedule::ScheduleNotFound do
    render text: 'Schedule not found', status: 404
  end

  before_action only: :show do
    render text: 'Locations not found', status: 404 unless params[:origin].present? && params[:destination].present?
  end

  def show
    schedule = PagingSchedule.for(request_for_schedule)
    respond_to do |format|
      format.json { render json: schedule.earliest_delivery_estimate, layout: false }
      format.html { render text: schedule.earliest_delivery_estimate.to_s, layout: false }
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
