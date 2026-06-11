# frozen_string_literal: true

module StubAeonClient
  # :nodoc:
  class Appointment < AeonRecord
    store :data, accessors: [:username, :readingRoomID, :startTime, :stopTime, :name, :availableToProxies, :appointmentStatus], coder: JSON

    def reading_room=(value)
      self.readingRoomID = value.id
    end

    def as_json(*)
      data.as_json(*).merge({ id:, readingRoom: reading_room, creationDate: created_at }.as_json(*))
    end

    def reading_room
      return if readingRoomID.blank?

      StubAeonClient::ReadingRoom.find(readingRoomID)
    end
  end
end
