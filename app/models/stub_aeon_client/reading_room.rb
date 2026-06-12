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

    def open_hours_on(date)
      openHours.find { |h| h['dayOfWeek'] == date.wday }
    end

    def open_range_on(date)
      start_of_day = date.in_time_zone
      open_time = Time.zone.parse(open_hours_on(date)['openTime'])
      close_time = Time.zone.parse(open_hours_on(date)['closeTime'])

      (start_of_day.change(hour: open_time.hour, min: open_time.min)..
        start_of_day.change(hour: close_time.hour, min: close_time.min))
    end

    def available_appointments(date)
      range = open_range_on(date)
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
end
