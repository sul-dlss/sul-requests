# frozen_string_literal: true

module Aeon
  # Wraps an Aeon reading room open hours record
  AvailableAppointment = Data.define(:start_time, :maximum_appointment_length) do
    def self.from_dynamic(dyn)
      new(
        start_time: Time.zone.parse(dyn['utcStartTime']),
        maximum_appointment_length: dyn['maximumAppointmentLengthMinutes'].minutes
      )
    end
  end
end
