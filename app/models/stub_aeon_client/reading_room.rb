# frozen_string_literal: true

module StubAeonClient
  # :nodoc:
  class ReadingRoom < AeonRecord
    store :data, accessors: [:name,
                             :availableSeats,
                             :timeZoneID,
                             :minAppointmentLength,
                             :maxAppointmentLength,
                             :appointmentPadding,
                             :appointmentIncrement,
                             :lastModifiedTime,
                             :sites,
                             :openHours,
                             :policies], coder: JSON

    def self.find_by(**kwargs)
      all.find { |rr| kwargs.all? { |k, v| rr.public_send(k) == v } }
    end

    def as_json(*)
      data.as_json(*).merge('id' => id)
    end

    def available_appointments(date, include_next_available: false) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      ranges = open_range_on(date)
      return [] if !include_next_available && ranges.empty?

      while ranges.empty? && date <= 1.year.from_now
        date += 1.day
        ranges = open_range_on(date)
      end

      ranges.flat_map do |range|
        range.step(30.minutes).map do |time|
          {
            utcStartTime: time.utc.iso8601,
            startTime: time.iso8601,
            seatsAvailable: availableSeats,
            maximumAppointmentLengthMinutes: (range.end - time) / 60
          }
        end
      end
    end

    private

    def open_hours_on(date)
      openHours.select { |h| h['dayOfWeek'] == date.wday }
    end

    def open_range_on(date)
      start_of_day = date.in_time_zone
      hour_blocks = open_hours_on(date)
      return [] if hour_blocks.empty?

      hour_blocks.map do |hours|
        open_time = Time.zone.parse(hours['openTime'])
        close_time = Time.zone.parse(hours['closeTime'])

        (start_of_day.change(hour: open_time.hour, min: open_time.min)..
          start_of_day.change(hour: close_time.hour, min: close_time.min))
      end
    end
  end
end
