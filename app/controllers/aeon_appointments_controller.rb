# frozen_string_literal: true

###
#  Controller for displaying Aeon appointments for a user
###
class AeonAppointmentsController < ApplicationController
  include AeonController

  before_action :load_appointments, except: [:available]
  before_action :load_appointment, only: [:edit, :update, :destroy]

  def index
    authorize! :read, Aeon::Appointment

    @appointments = @appointments.reject(&:cancelled?)

    request.variant = :sidebar if params[:variant] == 'sidebar'
  end

  def new
    authorize! :create, Aeon::Appointment

    @reading_rooms = Aeon::ReadingRoom.all
    @appointment = Aeon::Appointment.new

    request.variant = :modal if params[:modal]
  end

  def available
    @selected_time = params[:selected]
    @date = Date.parse(params.expect(:date))
    @available_appointments = AeonClient.new.available_appointments(reading_room_id: params.expect(:reading_room_id),
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

  def create # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    authorize! :create, Aeon::Appointment

    start_time = Time.zone.parse("#{create_params[:date]}T#{create_params[:start_time]}")
    stop_time = if create_params[:stop_time]
                  Time.zone.parse("#{create_params[:date]}T#{create_params[:stop_time]}")
                else
                  start_time + create_params[:duration].to_i.seconds
                end

    AeonClient.new.create_appointment(
      start_time: start_time,
      stop_time: stop_time,
      name: create_params[:name],
      reading_room_id: create_params[:reading_room_id],
      username: current_user.aeon.username
    )

    redirect_to aeon_appointments_path, notice: 'Appointment created successfully'
  end

  def update # rubocop:disable Metrics/AbcSize
    authorize! :update, @appointment
    start_time = Time.zone.parse("#{create_params[:date]}T#{create_params[:start_time]}")
    stop_time = if create_params[:stop_time]
                  Time.zone.parse("#{create_params[:date]}T#{create_params[:stop_time]}")
                else
                  start_time + create_params[:duration].to_i.seconds
                end

    AeonClient.new.update_appointment(params[:id], name: update_params[:name], start_time: start_time, stop_time: stop_time)

    redirect_to aeon_appointments_path, notice: 'Appointment created successfully'
  end

  def destroy
    authorize! :delete, @appointment
    AeonClient.new.cancel_appointment(params[:id])

    redirect_to aeon_appointments_path, notice: 'Appointment cancelled successfully'
  end

  private

  def load_appointments
    @appointments = current_user&.aeon&.appointments || []
  end

  def load_appointment
    @appointment = @appointments.find { |appt| appt.id == params[:id].to_i }
  end

  def create_params
    params.expect(aeon_appointment: [:date, :start_time, :stop_time, :duration, :name, :reading_room_id])
  end

  def update_params
    params.expect(aeon_appointment: [:date, :start_time, :stop_time, :duration, :name])
  end
end
