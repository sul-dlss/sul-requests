# frozen_string_literal: true

module Aeon
  # Wraps an Aeon reading room record
  class ReadingRoom
    include ActiveModel::Model

    def self.aeon_client
      Current.aeon_client
    end

    def self.all
      aeon_client.reading_rooms
    end

    def self.find_by(site:)
      all.find { |rr| rr.sites.include?(site) }
    end

    attr_accessor :id, :name, :available_seats, :time_zone_id, :min_appointment_length, :max_appointment_length,
                  :appointment_padding, :appointment_increment, :last_modified_time, :sites, :open_hours, :policies

    delegate :aeon_client, to: :class

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
        open_hours: Array(dyn['openHours']).map { |h| ReadingRoomOpenHours.from_dynamic(h) }.sort_by(&:day_of_week),
        policies: Array(dyn['policies']).map { |p| ReadingRoomPolicy.from_dynamic(p) }
      )
    end

    def appointment_item_limit
      Settings.aeon.default_appointment_item_limit
    end

    def available_appointments(date, **)
      aeon_client.available_appointments(reading_room_id: id, date: date, **)
    end

    def day_only_appointments?
      Settings.aeon.day_only_appointments.include?(sites.first)
    end

    def directions
      Settings.aeon.directions[sites.first]
    end

    OpenHoursDisplay = Data.define(:day_range, :hours)

    # Returns a human-readable set of open hours for the reading room that generally combines sequential days
    # with the same hours (the typical case for most locations), and groups together multiple hours for the same
    # day (e.g. ARS).
    def human_readable_hours # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      open_hours_by_range = @open_hours.slice_when { |i, j| format_hours(i) != format_hours(j) }

      display_groups = open_hours_by_range.map do |open_hours_with_same_times|
        first = open_hours_with_same_times.first
        last = open_hours_with_same_times.last

        if open_hours_with_same_times.one?
          OpenHoursDisplay.new(day_range: first.day_name, hours: format_hours(first))
        elsif (open_hours_with_same_times.last.day_of_week - open_hours_with_same_times.first.day_of_week) < open_hours_with_same_times.count # rubocop:disable Layout/LineLength
          OpenHoursDisplay.new(day_range: "#{first.day_name} - #{last.day_name}", hours: format_hours(first))
        else
          OpenHoursDisplay.new(day_range: open_hours_with_same_times.map(&:day_name).to_sentence, hours: format_hours(first))
        end
      end

      day_groups = display_groups.group_by(&:day_range).map do |day_range, hours|
        if hours.one?
          "#{day_range}, #{hours.first.hours}"
        else
          "#{day_range}, #{hours.map(&:hours).uniq.to_sentence}"
        end
      end

      day_groups.join(', ')
    end

    def next_appointment
      @next_appointment ||= available_appointments(Time.zone.now.to_date, include_next_available: true)&.first
    end

    def persisted? = id.present?

    private

    def format_hours(reading_room_open_hours)
      "#{reading_room_open_hours.open_time.strftime('%-l:%M')} - #{reading_room_open_hours.close_time.strftime('%-l:%M %P')}"
    end
  end
end
