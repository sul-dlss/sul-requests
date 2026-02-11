# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class AppointmentComponent < ViewComponent::Base
    attr_reader :appointment

    def initialize(appointment:)
      @appointment = appointment
    end

    def appointment_time_range
      format = '%-l:%M %P'
      start = appointment.start_time.strftime(format).sub(':00', '')
      stop = appointment.stop_time.strftime(format).sub(':00', '')

      "#{start} - #{stop} (#{appointment.start_time.zone})"
    end
  end
end
