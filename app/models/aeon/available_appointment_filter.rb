# frozen_string_literal: true

module Aeon
  # Filters available appointment slots against a user's existing appointments
  # to prevent double-booking. Slots that conflict are either removed entirely
  # or have their maximum length reduced so the new appointment ends before the
  # existing one starts.
  class AvailableAppointmentFilter
    MIN_APPOINTMENT_LENGTH = 30.minutes

    def initialize(available_appointments:, existing_appointments:)
      @available_appointments = available_appointments
      @existing_appointments = existing_appointments
    end

    def filter
      @available_appointments.filter_map { |slot| adjust_slot(slot) }
    end

    private

    def adjust_slot(slot)
      effective_max = effective_max_length(slot)

      return nil if effective_max.nil? || effective_max < MIN_APPOINTMENT_LENGTH

      return slot if effective_max == slot.maximum_appointment_length

      AvailableAppointment.new(start_time: slot.start_time, maximum_appointment_length: effective_max)
    end

    def effective_max_length(slot)
      slot_start = slot.start_time
      slot_end = slot_start + slot.maximum_appointment_length
      effective_max = slot.maximum_appointment_length

      @existing_appointments.each do |existing|
        next unless conflicts?(slot_start, slot_end, existing)

        # Existing appointment covers the slot's start time
        return nil if existing.start_time <= slot_start

        # Existing appointment starts during the slot's range
        capped = ((existing.start_time - slot_start) / 60).minutes
        effective_max = [effective_max, capped].min
      end

      effective_max
    end

    def conflicts?(slot_start, slot_end, existing)
      existing.start_time < slot_end && existing.stop_time > slot_start
    end
  end
end
