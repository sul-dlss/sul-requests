# frozen_string_literal: true

###
#  Controller for displaying Aeon reading room information
###
class AeonReadingRoomsController < ApplicationController
  include AeonController

  before_action :load_reading_rooms
  before_action :load_reading_room

  def available
    @date = Date.parse(params.expect(:date))
    @available_appointments = @reading_room.available_appointments(@date, include_next_available: true)
    @appointment_lengths = @available_appointments.map(&:maximum_appointment_length)
    @selected_time = params[:selected]

    respond_to do |format|
      format.html
      format.json
    end
  end

  private

  def load_reading_rooms
    @reading_rooms = Aeon::ReadingRoom.all
  end

  def load_reading_room
    reading_room_id = params.expect(:id).to_i

    @reading_room = @reading_rooms.find { |rr| rr.id == reading_room_id }
  end
end
