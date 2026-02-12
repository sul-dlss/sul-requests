# frozen_string_literal: true

###
#  Controller for displaying Aeon appointments for a user
###
class AeonAppointmentsController < ApplicationController
  def index
    authorize! :read, Aeon::Appointment

    @appointments = (current_user&.aeon&.appointments || []).reject(&:canceled?)
  end

  def new
    authorize! :create, Aeon::Appointment

    @reading_rooms = Aeon::ReadingRoom.all
    @appointment = Aeon::Appointment.new
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

  def destroy
    @appointment = current_user.aeon.appointments.find { |appt| appt.id == params[:id] }

    AeonClient.new.cancel_appointment(params[:id])

    redirect_to aeon_appointments_path, notice: 'Appointment cancelled successfully'
  end

  def create_params
    params.expect(aeon_appointment: [:date, :start_time, :stop_time, :duration, :name, :reading_room_id])
  end
end
