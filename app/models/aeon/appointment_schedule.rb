# frozen_string_literal: true

module Aeon
  # DatePicker schedule policy for Aeon reading-room appointments. Encodes the
  # reading room's lead-time windows, open hours, closures, and the
  # per-reading-room availability endpoint. When the reading room only allows
  # one appointment per day, existing marked dates become disabled to prevent
  # double-booking.
  class AppointmentSchedule < DatePicker::Schedule
    include Rails.application.routes.url_helpers

    def initialize(reading_room:, appointment_id: nil, existing_appointments: [], **)
      @reading_room = reading_room
      @appointment_id = appointment_id
      @existing_appointments = existing_appointments
      super(**)
    end

    def open_days
      @reading_room&.open_hours&.map(&:day_name) || super
    end

    def availability_url
      return if @reading_room.nil? || !Settings.aeon.date_picker_availability_enabled

      unavailable_dates_aeon_reading_room_path(@reading_room.id, appointment_id: @appointment_id)
    end

    def disabled_dates # rubocop:disable Metrics/CyclomaticComplexity
      closures = @reading_room&.fully_closed_dates&.map(&:iso8601) || []
      return closures unless @reading_room&.day_only_appointments? && @existing_appointments.any?

      closures + @existing_appointments
    end

    def default_min # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      next_start = @reading_room&.next_appointment&.start_time
      next_start ||= @reading_room&.appointment_min_lead_days&.days&.from_now # rubocop:disable Style/SafeNavigationChainLength

      (next_start&.to_date || Time.zone.today).iso8601
    end

    def default_max
      (@reading_room&.policies || []).filter_map do |policy|
        policy.appointment_max_lead_days.days.from_now.to_date.iso8601 if policy.appointment_max_lead_days
      end.max
    end
  end
end
