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
      @reading_room.deconflicted_available_appointments(date, user: current_user.aeon, excluding_id: appointment_id_param).any?
    end
    render json: { month: params[:month], unavailable_dates: dates.map(&:iso8601) }
  end

  private

  def bookable_dates_in(month)
    closed = @reading_room.fully_closed_dates.to_set
    month.all_month.select { |date| @reading_room.open_hours_on(date) && closed.exclude?(date) }
  end

  def appointment_id_param
    params[:appointment_id]&.to_i
  end

  def load_reading_room
    @reading_room = Aeon::ReadingRoom.find(params.expect(:id))
  end

  def load_appointments
    @date = (Date.parse(params.expect(:date)) if params[:date]) || Time.zone.now.to_date
    @available_appointments = @reading_room.deconflicted_available_appointments(
      @date, user: current_user.aeon, excluding_id: appointment_id_param, include_next_available: true
    )
    @appointment_lengths = @available_appointments.map(&:maximum_appointment_length)
  end
end
