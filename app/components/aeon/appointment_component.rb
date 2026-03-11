# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class AppointmentComponent < ViewComponent::Base
    attr_reader :appointment

    def initialize(appointment:)
      @appointment = appointment
    end

    def appointment_time_range
      start = l(appointment.start_time, format: :time_only).sub(':00', '')
      stop = l(appointment.stop_time, format: :time_only).sub(':00', '')

      "#{start} - #{stop} (#{appointment.start_time.zone})"
    end

    def appointment_date
      l(appointment.start_time, format: :date_only)
    end
  end
end
