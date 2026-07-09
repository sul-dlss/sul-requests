# frozen_string_literal: true

module Aeon
  # Renders the custom Stimulus date-picker for the Aeon appointment date field.
  #
  # Usage:
  #   <%= render Aeon::AppointmentDatePickerComponent.new(:date, form: f) %>
  #   <%= render Aeon::AppointmentDatePickerComponent.new(:date, form: f,
  #             data: { 'date-picker-disabled-value': ['2026-05-01'], 'date-picker-marked-value': ['2026-05-10'] }) %>
  class AppointmentDatePickerComponent < DatePickerComponent
    attr_reader :reading_room

    def initialize(key, reading_room: nil, **)
      super(key, **)
      @reading_room = reading_room || form.object.reading_room
    end

    def min # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      next_start = reading_room&.next_appointment&.start_time
      next_start ||= reading_room&.appointment_min_lead_days&.days&.from_now # rubocop:disable Style/SafeNavigationChainLength

      (next_start&.to_date || Time.zone.today).iso8601
    end

    def max
      (reading_room&.policies || []).filter_map do |policy|
        policy.appointment_max_lead_days.days.from_now.to_date.iso8601 if policy.appointment_max_lead_days
      end.max
    end

    def open_days
      reading_room&.open_hours&.map(&:day_name) || Date::DAYNAMES
    end

    def closures_dates
      reading_room&.fully_closed_dates || []
    end

    def availability_url
      return if reading_room.nil? || !Settings.aeon.date_picker_availability_enabled

      helpers.unavailable_dates_aeon_reading_room_path(reading_room.id, appointment_id: form&.object&.id)
    end

    def disabled_days
      return closures_dates.map(&:iso8601) unless data[:'date-picker-marked-value'] && reading_room&.day_only_appointments?

      closures_dates.map(&:iso8601) + data[:'date-picker-marked-value']
    end

    def controller_data
      data.merge(controller: "#{data[:controller]} date-picker").reverse_merge('date-picker-today-value': Time.zone.today.iso8601,
                                                                               'date-picker-min-value': min,
                                                                               'date-picker-max-value': max,
                                                                               'date-picker-disabled-value': disabled_days,
                                                                               'date-picker-open-days-value': open_days,
                                                                               'date-picker-availability-url-value': availability_url)
    end
  end
end
