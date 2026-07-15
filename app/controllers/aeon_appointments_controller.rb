# frozen_string_literal: true

###
#  Controller for displaying Aeon appointments for a user
###
class AeonAppointmentsController < ApplicationController
  include AeonController

  before_action :load_aeon_requests, only: [:index, :items, :update]
  before_action :load_appointments
  before_action :load_appointment, only: [:edit, :update, :destroy, :items]
  before_action :build_appointment, only: [:new, :create]
  before_action :load_reading_rooms, only: [:new]
  before_action :set_variant

  def index
    authorize! :read, Aeon::Appointment
  end

  def new
    authorize! :create, Aeon::Appointment
  end

  def edit
    authorize! :update, @appointment
  end

  def create # rubocop:disable Metrics/AbcSize
    authorize! :create, @appointment

    render :new, status: :unprocessable_content and return unless @appointment.save

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

    @appointment.assign_attributes(name: appointment_params[:name], start_time: start_time_param, stop_time: stop_time_param)
    render :edit, status: :unprocessable_content and return unless @appointment.save

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to :index, notice: 'Appointment updated successfully' }
    end
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
      [x.title, x.default_sort_key, -1 * x.creation_date.to_i]
    end
    @aeon_request_groups = Aeon::RequestGrouping.from_requests(requests)
  end

  private

  def load_reading_rooms
    @reading_rooms = Aeon::ReadingRoom.all
  end

  def build_appointment
    @appointment = Aeon::Appointment.new(
      start_time: start_time_param,
      stop_time: stop_time_param,
      name: appointment_params[:name],
      reading_room_id: reading_room&.id,
      reading_room: reading_room,
      username: current_user.aeon.username,
      user: current_user.aeon
    )
  end

  def reading_room
    return unless appointment_params[:reading_room_id]

    @reading_room ||= Aeon::ReadingRoom.find(appointment_params[:reading_room_id])
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

  def start_time_param
    return day_only_appointment_range&.begin if day_only_appointment_range
    return unless appointment_params[:start_time]

    parse_time(appointment_params[:date], appointment_params[:start_time])
  end

  def stop_time_param
    return day_only_appointment_range&.end if day_only_appointment_range

    stop_time = appointment_params[:stop_time]
    duration = appointment_params[:duration]
    return parse_time(appointment_params[:date], stop_time) if stop_time

    start_time_param + duration.to_i.seconds if start_time_param && duration
  end

  def parse_time(date, time)
    Time.zone.parse("#{date}T#{time}")
  end

  def day_only_appointment_range
    return if appointment_params[:date].blank?

    reading_room&.day_only_appointment_range(Date.parse(appointment_params[:date]))
  end

  def appointment_params
    return {} unless params[:aeon_appointment]

    params.expect(aeon_appointment: [:date, :start_time, :stop_time, :duration, :name, :reading_room_id])
  end
end
