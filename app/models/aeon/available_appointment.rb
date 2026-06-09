# frozen_string_literal: true

module Aeon
  # Wraps an Aeon reading room open hours record
  AvailableAppointment = Data.define(:start_time, :seats_available?, :maximum_appointment_length) do
    def self.from_dynamic(dyn)
      new(
        start_time: Time.zone.parse(dyn['utcStartTime']),
        seats_available?: dyn['seatsAvailable'].to_i.positive?,
        maximum_appointment_length: dyn['maximumAppointmentLengthMinutes'].minutes
      )
    end
  end
end
