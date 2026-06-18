# frozen_string_literal: true

module Aeon
  # Renders the custom Stimulus date-picker for the Aeon appointment date field.
  #
  # Usage:
  #   <%= render Aeon::AppointmentDatePickerComponent.new(:date, form: f) %>
  #   <%= render Aeon::AppointmentDatePickerComponent.new(:date, form: f,
  #             data: { 'date-picker-disabled-value': ['2026-05-01'], 'date-picker-marked-value': ['2026-05-10'] }) %>
  class AppointmentDatePickerComponent < ViewComponent::Base
    attr_reader :key, :form, :reading_room, :data

    def initialize(key, form: nil, reading_room: nil, data: {})
      @key = key
      @form = form
      @reading_room = reading_room || form.object.reading_room
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

    # Dates where a closure covers the entire span of open hours for that day.
    def closures_dates # rubocop:disable Metrics/AbcSize
      return [] if reading_room&.closures.blank?

      reading_room.closures.flat_map do |closure|
        closure.start_date.to_date.upto(closure.end_date.to_date).to_a.select do |date|
          hours_on_day = reading_room.open_hours_on(date)
          next if hours_on_day.nil?

          closure.cover?(hours_on_day.range_on(date))
        end
      end
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
                                                                               'date-picker-open-days-value': open_days)
    end
  end
end
