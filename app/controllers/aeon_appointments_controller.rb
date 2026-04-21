# frozen_string_literal: true

###
#  Controller for displaying Aeon appointments for a user
###
class AeonAppointmentsController < ApplicationController
  include AeonController
  include AeonSortable

  before_action :load_appointments, except: [:available]
  before_action :load_appointment, only: [:edit, :update, :destroy, :items]
  before_action :create_appointment, only: [:create]
  before_action :load_reading_rooms, only: [:new, :available]

  def index
    authorize! :read, Aeon::Appointment

    request.variant = :sidebar if params[:variant] == 'sidebar'
  end

  def new
    authorize! :create, Aeon::Appointment

    @appointment = Aeon::Appointment.new reading_room_id: @reading_room&.id, reading_room: @reading_room

    request.variant = :modal if params[:modal]
  end

  def available
    @selected_time = params[:selected]
    @date = Date.parse(params.expect(:date))

    @available_appointments = Current.aeon_client.available_appointments(reading_room_id: params.expect(:reading_room_id),
                                                                         date: @date, include_next_available: true)
    @appointment_lengths = @available_appointments.map(&:maximum_appointment_length)
    respond_to do |format|
      format.html
      format.json
    end
  end

  def edit
    authorize! :update, @appointment

    request.variant = :modal if params[:modal]
  end

  def create
    authorize! :create, Aeon::Appointment

    respond_to do |format|
      format.html { redirect_to aeon_appointments_path, notice: 'Appointment created successfully' }
      format.turbo_stream
    end
  end

  def update
    authorize! :update, @appointment

    Current.aeon_client.update_appointment(params[:id], name: update_params[:name], start_time: start_time, stop_time: stop_time)

    redirect_to aeon_appointments_path, notice: 'Appointment created successfully'
  end

  def destroy
    authorize! :delete, @appointment

    CancelAeonAppointmentJob.perform_now(@appointment, cancel_requests: params['cancel_items'] == 'true')

    redirect_to aeon_appointments_path, notice: 'Appointment cancelled successfully'
  end

  def items
    authorize! :read, @appointment

    requests = current_user.aeon.draft_requests.reject(&:digital?).select do |request|
      request.reading_room.id == @appointment.reading_room.id
    end
    requests = sort_aeon_requests(requests || [])
    @aeon_request_groups = Aeon::RequestGrouping.from_requests(requests)
  end

  private

  def load_reading_rooms
    @reading_rooms = Aeon::ReadingRoom.all

    return unless params[:reading_room_id]

    @reading_room = @reading_rooms.find { |rr| rr.id == params[:reading_room_id].to_i }
  end

  def create_appointment
    @appointment = Current.aeon_client.create_appointment(
      start_time: start_time,
      stop_time: stop_time,
      name: create_params[:name],
      reading_room_id: create_params[:reading_room_id],
      username: current_user.aeon.username
    )
  end

  def load_appointments
    @appointments = current_user&.aeon&.appointments || []
    @appointments = @appointments.sort_by(&:start_time)
  end

  def load_appointment
    @appointment = @appointments.find { |appt| appt.id == params[:id].to_i }
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
