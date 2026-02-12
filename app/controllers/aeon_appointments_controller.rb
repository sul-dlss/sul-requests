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

  def create # rubocop:disable Metrics/AbcSize
    authorize! :create, Aeon::Appointment

    AeonClient.new.create_appointment(
      start_time: Time.zone.parse(create_params[:start_time]),
      end_time: Time.zone.parse(create_params[:end_time]),
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
    params.expect(aeon_appointment: [:start_time, :end_time, :name, :reading_room_id])
  end
end
