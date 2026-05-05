# frozen_string_literal: true

module Aeon
  # Renders the custom Stimulus date-picker for the Aeon appointment date field.
  #
  # Usage:
  #   <%= render Aeon::AppointmentDatePickerComponent.new(form: f) %>
  #   <%= render Aeon::AppointmentDatePickerComponent.new(form: f, disabled: ['2026-05-01'], marked: ['2026-05-10']) %>
  class AppointmentDatePickerComponent < ViewComponent::Base
    attr_reader :form, :disabled, :marked

    def initialize(form:, disabled: [], marked: [])
      @form = form
      @disabled = disabled
      @marked = marked
    end

    def min
      appointment = form.object
      next_start = appointment.reading_room&.next_appointment&.start_time
      next_start&.to_date&.iso8601 || Time.zone.today.iso8601
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
