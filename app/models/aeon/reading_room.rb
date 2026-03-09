# frozen_string_literal: true

module Aeon
  # Wraps an Aeon reading room record
  class ReadingRoom
    include ActiveModel::Model

    def self.aeon_client
      AeonClient.new
    end

    def self.all
      @all ||= aeon_client.reading_rooms
    end

    def self.find_by(site:)
      all.find { |rr| rr.sites.include?(site) }
    end

    attr_accessor :id, :name, :available_seats, :time_zone_id, :min_appointment_length, :max_appointment_length,
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

    def daily_item_limit
      Settings.aeon.default_daily_item_limit
    end

    def available_appointments(date, **)
      AeonClient.new.available_appointments(reading_room_id: id, date: date, **)
    end

    def day_only_appointments?
      Settings.aeon.day_only_appointments.include?(sites.first)
    end

    def grouped_hours
      @grouped_hours = {}
      @open_hours.each do |oh|
        hour_str = "#{Time.zone.parse(oh.open_time).strftime('%l:%M')} - #{Time.zone.parse(oh.close_time).strftime('%l:%M %p')}"
        if @grouped_hours.key?(hour_str)
          @grouped_hours[hour_str].push(oh.day_name)
        else
          @grouped_hours[hour_str] = [oh.day_name]
        end
      end
      @grouped_hours
    end

    def human_readable_hours
      grouped_hours.map do |hours, days|
        "#{days.first} - #{days.last}, #{hours}"
      end.join(', ')
    end

    def next_appointment
      @next_appointment ||= available_appointments(Time.zone.now.to_date, include_next_available: true)&.first
    end

    def persisted? = id.present?
  end
end
