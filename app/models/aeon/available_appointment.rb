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

    def trimmed_for(conflicts)
      return self if conflicts.empty?
      return nil if conflicts.any? { |c| c.cover?(start_time) }

      truncate_to(earliest_conflict_in_window(conflicts))
    end

    private

    def earliest_conflict_in_window(conflicts)
      slot_end = start_time + maximum_appointment_length
      conflicts.map(&:begin).select { |t| t > start_time && t < slot_end }.min
    end

    def truncate_to(boundary)
      return self unless boundary

      with(maximum_appointment_length: (boundary - start_time).to_i.seconds)
    end
  end
end
