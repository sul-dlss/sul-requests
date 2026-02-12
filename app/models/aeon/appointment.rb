# frozen_string_literal: true

module Aeon
  # Wraps an Aeon appointment record
  class Appointment
    attr_reader :id, :username, :reading_room_id, :start_time, :stop_time,
                :name, :appointment_status, :reading_room, :creation_date

    attr_writer :requests

    def self.from_dynamic(dyn) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      new(
        id: dyn['id'],
        username: dyn['username'],
        start_time: dyn['startTime'] && Time.zone.parse(dyn['startTime']),
        stop_time: dyn['stopTime'] && Time.zone.parse(dyn['stopTime']),
        name: dyn['name'],
        available_to_proxies: dyn['availableToProxies'],
        appointment_status: dyn['appointmentStatus'],
        reading_room: dyn['readingRoom'] ? ReadingRoom.from_dynamic(dyn['readingRoom']) : nil,
        reading_room_id: dyn['readingRoomID'],
        creation_date: Time.zone.parse(dyn.fetch('creationDate'))
      )
    end

    def initialize(id: nil, username: nil, start_time: nil, # rubocop:disable Metrics/ParameterLists
                   stop_time: nil, name: nil, available_to_proxies: nil,
                   appointment_status: nil, reading_room: nil, reading_room_id: nil, creation_date: nil)
      @id = id
      @username = username
      @reading_room_id = reading_room_id
      @start_time = start_time
      @stop_time = stop_time
      @name = name
      @available_to_proxies = available_to_proxies
      @appointment_status = appointment_status
      @reading_room = reading_room
      @reading_room_id = reading_room_id
      @creation_date = creation_date
    end

    def available_to_proxies?
      @available_to_proxies
    end

    def reading_room?
      reading_room_id.present?
    end

    def requests
      @requests ||= []
    end

    def to_model = self
    def model_name = ActiveModel::Name.new(self.class)
    def persisted? = id.present?
  end
end
