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

    def date_label
      return unless appointment.start_time
      return l(appointment.start_time, format: :date_only) unless multi_day?

      "#{l(appointment.start_time, format: :date_only)} - #{l(appointment.stop_time, format: :date_only)}"
    end

    def time_range_label
      return if appointment.start_time.nil? || multi_day?

      return open_hours_label if appointment.reading_room&.day_only_appointments?
      return formatted_time_range if appointment.stop_time

      l(appointment.start_time, format: :time_only)
    end

    private

    def multi_day?
      appointment.stop_time && appointment.stop_time.to_date > appointment.start_time.to_date
    end

    def open_hours_label
      return unless show_open_hours?
      return 'No public hours' unless distinct_start_and_stop?

      "Open hours: #{formatted_time_range}"
    end

    def distinct_start_and_stop?
      appointment.stop_time && appointment.start_time != appointment.stop_time
    end

    def formatted_time_range
      "#{l(appointment.start_time, format: :time_only)} - #{l(appointment.stop_time, format: :time_only)}"
    end
  end
end
