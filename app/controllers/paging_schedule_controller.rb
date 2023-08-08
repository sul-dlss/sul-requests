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

  def index
    authorize! :manage, PagingSchedule
    @paging_schedule = PagingSchedule.schedule
  end

  def show
    respond_to do |format|
      format.json { render json: @schedule.earliest_delivery_estimate, layout: false }
      format.html { render plain: @schedule.earliest_delivery_estimate.to_s, layout: false }
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
    @schedule = PagingSchedule.for(request_for_schedule)
  end

  def request_for_schedule
    destination = params[:destination]
    destination = map_to_library(destination) if Settings.ils.bib_model == 'Folio::Instance'
    Request.new(
      origin: params[:origin],
      destination:
    )
  end

  # For FOLIO, destination is specified as service point
  # Convert service point to library for scheduling and library hours
  def map_to_library(service_point_code)
    service_point_id = get_service_point_id(service_point_code)
    library_id = get_library_for_service_point(service_point_id)
    return nil if library_id.nil?

    # Find the library code associated with this library id
    Folio::Types.instance.get_type('libraries').find { |library| library['id'] == library_id }['code']
  end

  # Find the service point ID based on this service point code
  def get_service_point_id(service_point_code)
    Folio::Types.instance.service_points.values.find { |v| v.code == service_point_code }&.id
  end

  # Find the library id for the location with which this service point is associated
  def get_library_for_service_point(service_point_id)
    loc = Folio::Types.instance.get_type('locations').find { |location| location['primaryServicePoint'] == service_point_id }
    loc.present? && loc.key?('libraryId') ? loc['libraryId'] : nil
  end
end
