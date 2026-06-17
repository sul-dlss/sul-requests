# frozen_string_literal: true

###
#  Controller for displaying Aeon reading room information
###
class AeonReadingRoomsController < ApplicationController
  include AeonController

  before_action :load_reading_room
  before_action :load_appointments

  def available
    @selected_time = params[:selected]

    respond_to do |format|
      format.html
      format.json
    end
  end

  private

  def load_reading_room
    @reading_room = Aeon::ReadingRoom.find(params.expect(:id))
  end

  def load_appointments
    @date = (Date.parse(params.expect(:date)) if params[:date]) || Time.zone.now.to_date
    @available_appointments = @reading_room.available_appointments(@date, include_next_available: true)
    @available_appointments_on_selected_date = available_appointments_without_conflicts(@available_appointments)
    @appointment_lengths = @available_appointments_on_selected_date.map(&:maximum_appointment_length)
  end

  def available_appointments_without_conflicts(available_appointments)
    existing_appointments = current_user.aeon.appointments
                                        .for_reading_room(@reading_room)
                                        .reject { |a| a.id == params[:appointment_id].to_i }
    Aeon::AppointmentDeconflictionService.new(available_appointments:, existing_appointments:).call
  end
end
