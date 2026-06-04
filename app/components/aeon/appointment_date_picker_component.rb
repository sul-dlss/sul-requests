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

    def min
      next_start = reading_room&.next_appointment&.start_time
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

    def closures_dates # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      return [] if reading_room&.closures.blank?

      # get the closures for a reading room:
      closures = reading_room.closures

      # get the open hours for a reading room
      open_hours = reading_room.open_hours

      # make a list of closed dates (where a closure covers the entire day a reading room is actually open)
      closures.flat_map do |closure|
        closure.start_date.to_date.upto(closure.end_date.to_date).to_a.select do |date|
          hours_on_day = open_hours.find { |oh| oh.day_name == date.strftime('%A') }

          next if hours_on_day.nil?

          open_hours_range_on_date = date.to_time.change(hour: hours_on_day.open_time.hour,
                                                         min: hours_on_day.open_time.min)..date.to_time.change(
                                                           hour: hours_on_day.close_time.hour, min: hours_on_day.close_time.min
                                                         )

          closure.cover?(open_hours_range_on_date)
        end
      end
    end

    def controller_data
      data.merge(controller: "#{data[:controller]} date-picker").reverse_merge('date-picker-min-value': min,
                                                                               'date-picker-max-value': max,
                                                                               'date-picker-disabled-value': closures_dates.map(&:iso8601),
                                                                               'date-picker-open-days-value': open_days)
    end
  end
end
