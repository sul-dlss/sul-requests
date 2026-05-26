# frozen_string_literal: true

module Aeon
  # Renders the custom Stimulus date-picker for the Aeon appointment date field.
  #
  # Usage:
  #   <%= render Aeon::AppointmentDatePickerComponent.new(form: f) %>
  #   <%= render Aeon::AppointmentDatePickerComponent.new(form: f, disabled: ['2026-05-01'], marked: ['2026-05-10']) %>
  class AppointmentDatePickerComponent < ViewComponent::Base
    attr_reader :appointment, :disabled, :marked

    delegate :reading_room, to: :appointment

    def initialize(appointment:, disabled: [], marked: [])
      @appointment = appointment
      @disabled = disabled
      @marked = marked
    end

    def min
      next_start&.to_date&.iso8601
    end

    def next_start
      return Time.zone.today unless reading_room

      reading_room.next_appointment&.start_time || reading_room.appointment_min_lead_days&.days&.from_now
    end

    def controller_data
      attrs = { controller: 'date-picker' }
      attrs[:'date-picker-min-value'] = min if min.present?
      attrs[:'date-picker-disabled-value'] = disabled.to_json if disabled.any?
      attrs[:'date-picker-marked-value'] = marked.to_json if marked.any?
      { data: attrs }
    end
  end
end
