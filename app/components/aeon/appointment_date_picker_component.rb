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

    def controller_data
      data.merge(controller: "#{data[:controller]} date-picker").reverse_merge('date-picker-min-value': min)
    end
  end
end
