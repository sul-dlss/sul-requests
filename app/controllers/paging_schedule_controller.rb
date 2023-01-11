# frozen_string_literal: true

###
#  Controller for returning the paging schedule for async requests
###
class PagingScheduleController < ApplicationController
  rescue_from PagingSchedule::ScheduleNotFound do
    render plain: 'Schedule not found', status: :not_found
  end

  before_action only: [:show, :open] do
    render plain: 'Locations not found', status: :not_found unless params[:origin].present? && params[:destination].present?
  end

  before_action :load_schedule, only: [:show, :open]

  def show
    respond_to do |format|
      format.json { render json: @schedule.earliest_delivery_estimate, layout: false }
      format.html { render plain: @schedule.earliest_delivery_estimate.to_s, layout: false }
    end
  end

  def index
    authorize! :manage, PagingSchedule
    @paging_schedule = PagingSchedule.schedule
  end

  def open
    date = begin
      Date.parse(params[:date])
    rescue ArgumentError
      raise PagingSchedule::ScheduleNotFound, "Unable to parse date: #{date}"
    end

    respond_to do |format|
      format.html { render plain: @schedule.valid?(date) ? 'true' : 'false', layout: false }
      format.json { render json: { ok: @schedule.valid?(date) }, layout: false }
    end
  end

  private

  def load_schedule
    @schedule = PagingSchedule.for(request_for_schedule)
  end

  def request_for_schedule
    Request.new(
      origin: params[:origin],
      destination: params[:destination]
    )
  end
end
