# frozen_string_literal: true

###
#  Controller for returning the paging schedule for async requests
###
class PagingScheduleController < ApplicationController
  rescue_from PagingSchedule::ScheduleNotFound do
    turbo_frame = helpers.content_tag('turbo-frame', style: 'display:none', id: 'earliestAvailable') { 'No date/time estimate' }
    turbo_frame += helpers.content_tag('body') { 'Schedule not found' }
    render html: turbo_frame, layout: false, status: :not_found
  end

  before_action only: [:show, :open] do
    render plain: 'Locations not found', status: :not_found unless params[:origin_library].present? && params[:destination].present?
  end

  before_action :load_schedule, only: [:show, :open]

  def index
    authorize! :manage, PagingSchedule

    load_schedule if params[:origin_location].present? && params[:destination].present?
  end

  def show
    respond_to do |format|
      format.json { render json: @schedule.earliest_delivery_estimate, layout: false }
      format.html do
        turbo_frame = helpers.content_tag('turbo-frame', id: 'earliestAvailable') { @schedule.earliest_delivery_estimate.to_s }
        render html: turbo_frame, layout: false
      end
    end
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
    @schedule = PagingSchedule.new(from: origin_location, to: destination_library_code,
                                   library_code: fallback_library_code, time: params[:date] ? Time.zone.parse(params[:date]) : nil)
  end

  def origin_location
    return @origin_location if defined?(@origin_location)

    @origin_location = Folio::Types.locations.find_by(code: params[:origin_location])
  end

  def destination_library_code
    params[:destination]
  end

  def fallback_library_code
    return origin_location.library.code if origin_location.present?

    Honeybadger.notify('PagingScheduleController#load_schedule: origin_location not found', context: { params: })

    params[:origin_library]
  end
end
