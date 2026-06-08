# frozen_string_literal: true

module Aeon
  # Render an accordion item for a digitization form step.
  class AppointmentDurationSelectorComponent < ViewComponent::Base
    attr_reader :selected, :reading_room, :form

    ALL_OPTIONS = [30.minutes, 1.hour, 1.5.hours, 2.hours, 3.hours, 4.hours].freeze

    def initialize(form:, reading_room: nil, selected: '')
      @selected = selected
      @reading_room = reading_room
      @form = form
    end

    def options
      ALL_OPTIONS.grep(valid_range)
    end

    def valid_range(min: ALL_OPTIONS.min, max: ALL_OPTIONS.max)
      min = reading_room.min_appointment_length&.minutes if reading_room&.min_appointment_length.present?
      max = reading_room.max_appointment_length&.minutes if reading_room&.max_appointment_length.present?

      min..max
    end
  end
end
