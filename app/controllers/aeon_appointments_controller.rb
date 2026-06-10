# frozen_string_literal: true

###
#  Controller for displaying Aeon appointments for a user
###
class AeonAppointmentsController < ApplicationController
  include AeonController
  include AeonSortable

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
      appt.reading_room.id == @appointment.reading_room.id
    end.select(&:editable?).sort_by(&:sort_key)

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
    authorize! :delete, @appointment

    CancelAeonAppointmentJob.perform_now(@appointment, cancel_requests: params['cancel_items'] == 'true')

    respond_to do |format|
      format.html { redirect_to aeon_appointments_path, notice: 'Appointment cancelled successfully' }
      format.turbo_stream
    end
  end

  def items
    authorize! :read, @appointment

    requests = current_user.aeon.saved_for_later_requests.reject(&:digital?).select do |request|
      request.reading_room.id == @appointment.reading_room.id
    end
    requests = sort_aeon_requests(requests || [])
    @aeon_request_groups = Aeon::RequestGrouping.from_requests(requests)
  end

  def add_items
    authorize! :update, Aeon::Request

    process_items(params[:items_added], :submitted?, @appointment.id)

    process_items(params[:items_removed], :saved_for_later?, nil)
    redirect_to aeon_appointments_path(anchor: helpers.dom_id(@appointment))
  end

  private

  def process_items(items, skip_method, appointment_id)
    items&.each do |transaction_number|
      request = current_user.aeon.requests.find { |request| request.transaction_number == transaction_number.to_i }
      next if request.send(skip_method)

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
    @appointments = current_user&.aeon&.appointments || []
    @appointments = @appointments.sort_by(&:start_time)
  end

  def load_appointment
    @appointment = @appointments.find { |appt| appt.id == (params[:aeon_appointment_id] || params[:id]).to_i }
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
