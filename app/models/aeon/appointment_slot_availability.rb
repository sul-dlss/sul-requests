# frozen_string_literal: true

module Aeon
  # Aeon appointment slot availability for a specific user in a specific reading room.
  class AppointmentSlotAvailability
    def initialize(reading_room:, user:)
      @reading_room = reading_room
      @user = user
    end

    def slots_on(date, excluding_id: nil, include_next_available: false)
      AppointmentDeconflictionService.new(
        available_appointments: @reading_room.available_appointments(date, include_next_available:),
        existing_appointments: existing_appointments(excluding_id:)
      ).call
    end

    def available_at?(range:, excluding_id: nil)
      duration = range.end - range.begin
      slots_on(range.begin.to_date, excluding_id:).any? do |slot|
        slot.start_time.to_i == range.begin.to_i && slot.maximum_appointment_length >= duration
      end
    end

    private

    def existing_appointments(excluding_id:)
      @user.appointments.for_reading_room(@reading_room).reject { |a| a.id == excluding_id }
    end
  end
end
