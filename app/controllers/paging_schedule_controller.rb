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
    destination = map_service_point_to_library(destination) if Settings.ils.bib_model == 'Folio::Instance'
    Request.new(
      origin: params[:origin],
      destination: destination
    )
  end

  # For FOLIO, destination is specified as service point
  # Convert service point to library for scheduling and library hours
  def map_service_point_to_library(service_point_code)
    libraries = Folio::Types.instance.get_type("libraries")
    locations = Folio::Types.instance.get_type("locations")
    service_points = Folio::Types.instance.service_points.values
    # Find the service point ID based on this service point code
    service_point_id = service_points.find { |v| v.code == service_point_code }&.id
    # Find the library id for the location with which this service point is associated
    library_id = locations.find { |location| location["primaryServicePoint"] == service_point_id }["libraryId"]
    # Find the library code associated with this library
    libraries.find{ |library| library["id"] == library_id }["code"]
  end

 
end
