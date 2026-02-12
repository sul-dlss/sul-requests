# frozen_string_literal: true

module Aeon
  # Wraps an Aeon reading room record
  class ReadingRoom
    attr_reader :id, :name, :available_seats, :time_zone_id, :min_appointment_length, :max_appointment_length,
                :appointment_padding, :appointment_increment, :last_modified_time, :sites, :open_hours, :policies

    def self.from_dynamic(dyn) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      new(
        id: dyn['id'],
        name: dyn['name'],
        available_seats: dyn['availableSeats'],
        time_zone_id: dyn['timeZoneID'],
        min_appointment_length: dyn['minAppointmentLength'],
        max_appointment_length: dyn['maxAppointmentLength'],
        appointment_padding: dyn['appointmentPadding'],
        appointment_increment: dyn['appointmentIncrement'],
        last_modified_time: Time.zone.parse(dyn['lastModifiedTime'].to_s),
        sites: dyn['sites'] || [],
        open_hours: Array(dyn['openHours']).map { |h| ReadingRoomOpenHours.from_dynamic(h) },
        policies: Array(dyn['policies']).map { |p| ReadingRoomPolicy.from_dynamic(p) }
      )
    end

    def self.all
      @all ||= AeonClient.new.reading_rooms
    end

    def initialize(id: nil, name: nil, available_seats: nil, time_zone_id: nil, # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
                   min_appointment_length: nil, max_appointment_length: nil,
                   appointment_padding: nil, appointment_increment: nil, last_modified_time: nil,
                   sites: [], open_hours: [], policies: [])
      @id = id
      @name = name
      @available_seats = available_seats
      @time_zone_id = time_zone_id
      @min_appointment_length = min_appointment_length
      @max_appointment_length = max_appointment_length
      @appointment_padding = appointment_padding
      @appointment_increment = appointment_increment
      @last_modified_time = last_modified_time
      @sites = sites
      @open_hours = open_hours
      @policies = policies
    end

    def daily_item_limit
      Settings.aeon.default_daily_item_limit
    end
  end
end
