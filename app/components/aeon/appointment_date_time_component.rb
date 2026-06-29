# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class AppointmentDateTimeComponent < ViewComponent::Base
    attr_reader :appointment, :icon_class

    def initialize(appointment:, icon_class: 'me-2', show_open_hours: true, location: nil)
      @appointment = appointment
      @icon_class = icon_class
      @show_open_hours = show_open_hours
      @location = location
    end

    def show_open_hours?
      @show_open_hours
    end

    def time_range_label
      return unless appointment.start_time

      if appointment.reading_room&.day_only_appointments?
        return unless show_open_hours?
        return 'No public hours' unless distinct_start_and_stop?

        "Open hours: #{formatted_time_range}"
      elsif appointment.stop_time
        formatted_time_range
      else
        l(appointment.start_time, format: :time_only)
      end
    end

    private

    def distinct_start_and_stop?
      appointment.stop_time && appointment.start_time != appointment.stop_time
    end

    def formatted_time_range
      "#{l(appointment.start_time, format: :time_only)} - #{l(appointment.stop_time, format: :time_only)}"
    end
  end
end
