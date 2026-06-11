# frozen_string_literal: true

module StubAeonClient
  # :nodoc:
  class ReadingRoomsController < StubAeonClient::ApplicationController
    before_action :load_reading_room, except: [:index]

    def index
      render json: StubAeonClient::ReadingRoom.all
    end

    def closures
      render json: @reading_room.closures
    end

    def available_appointments
      render json: @reading_room.available_appointments(Date.parse(params.expect(:date)))
    end

    private

    def load_reading_room
      @reading_room = StubAeonClient::ReadingRoom.find(params.expect(:id))
    end
  end
end
