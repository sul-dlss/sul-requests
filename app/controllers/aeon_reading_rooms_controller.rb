# frozen_string_literal: true

###
#  Controller for displaying Aeon reading room information
###
class AeonReadingRoomsController < ApplicationController
  include AeonController

  before_action :load_reading_room
  before_action :load_appointments, only: :available

  def available
    @selected_time = params[:selected]

    respond_to do |format|
      format.html
      format.json
    end
  end

  def unavailable_dates
    month = Date.strptime(params.expect(:month), '%Y-%m')
    dates = bookable_dates_in(month).reject do |date|
      deconflict(@reading_room.available_appointments(date)).any?
    end
    render json: { month: params[:month], unavailable_dates: dates.map(&:iso8601) }
  end

  private

  def bookable_dates_in(month)
    closed = @reading_room.fully_closed_dates.to_set
    month.all_month.select { |date| @reading_room.open_hours_on(date) && closed.exclude?(date) }
  end

  def deconflict(available_appointments)
    Aeon::AppointmentDeconflictionService.new(
      available_appointments:,
      existing_appointments: existing_appointments_for_deconfliction
    ).call
  end

  def existing_appointments_for_deconfliction
    current_user.aeon.appointments
                .for_reading_room(@reading_room)
                .reject { |a| a.id == params[:appointment_id].to_i }
  end

  def load_reading_room
    @reading_room = Aeon::ReadingRoom.find(params.expect(:id))
  end

  def load_appointments
    @date = (Date.parse(params.expect(:date)) if params[:date]) || Time.zone.now.to_date
    @available_appointments = @reading_room.available_appointments(@date, include_next_available: true)
    @available_appointments_on_selected_date = deconflict(@available_appointments)
    @appointment_lengths = @available_appointments_on_selected_date.map(&:maximum_appointment_length)
  end
end
