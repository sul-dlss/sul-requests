# frozen_string_literal: true

###
#  Controller for displaying Aeon appointments for a user
###
class AeonAppointmentsController < ApplicationController
  include AeonController

  before_action :load_aeon_requests, only: [:index, :items, :add_items]
  before_action :load_appointments
  before_action :load_appointment, only: [:edit, :update, :destroy, :items, :add_items]
  before_action :build_appointment, only: [:create]
  before_action :load_reading_rooms, only: [:new]

  def index
    authorize! :read, Aeon::Appointment

    request.variant = :sidebar if params[:variant] == 'sidebar'
  end

  def new
    authorize! :create, Aeon::Appointment

    @appointment = Aeon::Appointment.new reading_room_id: @reading_room&.id, reading_room: @reading_room

    request.variant = :modal if params[:modal]
  end

  def edit
    authorize! :update, @appointment

    request.variant = :modal if params[:modal]
  end

  def create # rubocop:disable Metrics/AbcSize
    authorize! :create, Aeon::Appointment

    return head :unprocessable_content unless @appointment.save

    @other_reading_room_appointments = (@appointments + [@appointment]).select do |appt|
      appt.reading_room.id == @appointment.reading_room.id && can?(:update, appt)
    end.sort_by(&:sort_key)

    respond_to do |format|
      format.html { redirect_to aeon_appointments_path, notice: 'Appointment created successfully' }
      format.turbo_stream
    end
  end

  def update
    authorize! :update, @appointment

    @appointment.assign_attributes(name: update_params[:name], start_time: start_time, stop_time: stop_time)
    return head :unprocessable_content unless @appointment.save

    redirect_to aeon_appointments_path, notice: 'Appointment updated successfully'
  end

  def destroy
    authorize! :destroy, @appointment

    CancelAeonAppointmentJob.perform_now(@appointment, cancel_requests: params['cancel_items'] == 'true')

    respond_to do |format|
      format.html { redirect_to aeon_appointments_path, notice: 'Appointment cancelled successfully' }
      format.turbo_stream
    end
  end

  def items
    authorize! :read, @appointment

    requests = @aeon_requests.for_reading_room(@appointment.reading_room).saved_for_later.sort_by do |x|
      [x.title, x.sort_key, -1 * x.creation_date.to_i]
    end
    @aeon_request_groups = Aeon::RequestGrouping.from_requests(requests)
  end

  def add_items # rubocop:disable Metrics/AbcSize
    authorize! :update, Aeon::Request

    process_items(@aeon_requests.find(Array(params[:items_added])).saved_for_later, @appointment.id)
    process_items(@aeon_requests.find(Array(params[:items_removed])).submitted, nil)

    redirect_to aeon_appointments_path(anchor: helpers.dom_id(@appointment))
  end

  private

  def process_items(requests, appointment_id)
    requests&.each do |request|
      Aeon::UpdateRequestService.new(request, { appointment_id: }).call
    end
  end

  def load_reading_rooms
    @reading_rooms = Aeon::ReadingRoom.all

    return unless params[:reading_room_id]

    @reading_room = Aeon::ReadingRoom.find(params[:reading_room_id])
  end

  def build_appointment
    reading_room = Aeon::ReadingRoom.find(create_params[:reading_room_id])
    @appointment = Aeon::Appointment.new(
      start_time: start_time,
      stop_time: stop_time,
      name: create_params[:name],
      reading_room_id: reading_room.id,
      reading_room: reading_room,
      username: current_user.aeon.username
    )
  end

  def load_appointments
    @appointments = current_user.aeon.appointments
  end

  def load_appointment
    @appointment = @appointments.find(params[:aeon_appointment_id] || params[:id])
  end

  def load_aeon_requests
    @aeon_requests = current_user.aeon.requests
  end

  def start_time
    Time.zone.parse("#{create_params[:date]}T#{create_params[:start_time]}")
  end

  def stop_time
    if create_params[:stop_time]
      Time.zone.parse("#{create_params[:date]}T#{create_params[:stop_time]}")
    else
      start_time + create_params[:duration].to_i.seconds
    end
  end

  def create_params
    params.expect(aeon_appointment: [:date, :start_time, :stop_time, :duration, :name, :reading_room_id])
  end

  def update_params
    params.expect(aeon_appointment: [:date, :start_time, :stop_time, :duration, :name])
  end
end
