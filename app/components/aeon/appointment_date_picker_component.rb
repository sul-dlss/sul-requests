# frozen_string_literal: true

module Aeon
  # Renders the custom Stimulus date-picker for the Aeon appointment date field.
  #
  # Usage:
  #   <%= render Aeon::AppointmentDatePickerComponent.new(:date, form: f) %>
  #   <%= render Aeon::AppointmentDatePickerComponent.new(:date, form: f,
  #             data: { 'date-picker-disabled-value': ['2026-05-01'], 'date-picker-marked-value': ['2026-05-10'] }) %>
  class AppointmentDatePickerComponent < ViewComponent::Base
    attr_reader :key, :form, :reading_room, :user_appointments, :data

    def initialize(key, form: nil, reading_room: nil, user_appointments: [], data: {})
      @key = key
      @form = form
      @reading_room = reading_room || form.object.reading_room
      @user_appointments = user_appointments
      @data = data
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

    # Dates with no usable gap in open hours, given the user's appointments
    # and the reading room's closures.
    def dates_with_no_room
      return [] unless reading_room && max

      AvailabilityCalendar.new(reading_room:, user_appointments:).dates_with_no_room(Date.parse(min)..Date.parse(max))
    end

    def disabled_dates
      dates_with_no_room.map(&:iso8601)
    end

    def controller_data
      data.merge(controller: "#{data[:controller]} date-picker").reverse_merge('date-picker-today-value': Time.zone.today.iso8601,
                                                                               'date-picker-min-value': min,
                                                                               'date-picker-max-value': max,
                                                                               'date-picker-disabled-value': disabled_dates,
                                                                               'date-picker-open-days-value': open_days)
    end
  end
end
