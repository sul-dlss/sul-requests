# frozen_string_literal: true

module Aeon
  # Deconflict available appointments, considering a user's existing appointments for the same reading room
  class AppointmentDeconflictionService
    attr_reader :available_appointments, :existing_appointments

    def initialize(available_appointments:, existing_appointments:)
      @available_appointments = available_appointments
      @existing_appointments = existing_appointments
    end

    def call
      available_appointments.filter_map { |available_appointment| adjust_for_conflicts(available_appointment) }
    end

    private

    def existing_appointment_ranges
      existing_appointments.map { |appt| appt.start_time...appt.stop_time }
    end

    def adjust_for_conflicts(available_appointment)
      return nil if wholly_conflicted?(available_appointment)

      conflict = earliest_conflicting_start_time_for(available_appointment)
      return shortened_available_appointment_for(available_appointment, conflict) if conflict

      available_appointment
    end

    def wholly_conflicted?(available_appointment)
      existing_appointment_ranges.any? { |existing_appt| existing_appt.cover?(available_appointment.start_time) }
    end

    def earliest_conflicting_start_time_for(available_appointment)
      stop_time = available_appointment.start_time + available_appointment.maximum_appointment_length
      existing_appointment_ranges.map(&:begin).select do |start_time|
        start_time > available_appointment.start_time && start_time < stop_time
      end.min
    end

    def shortened_available_appointment_for(available_appointment, conflict_start_time)
      shortened_appointment_length = (conflict_start_time - available_appointment.start_time).to_i.seconds
      AvailableAppointment.new(start_time: available_appointment.start_time, maximum_appointment_length: shortened_appointment_length)
    end
  end
end
