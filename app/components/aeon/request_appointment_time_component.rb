# frozen_string_literal: true

module Aeon
  # Render a request's appointment time
  class RequestAppointmentTimeComponent < ViewComponent::Base
    attr_reader :request

    delegate :appointment, :appointment?, :draft?, to: :request

    def initialize(request:, with_reading_room: true)
      @request = request
      @with_reading_room = with_reading_room
    end

    def render?
      appointment? && !draft?
    end

    def appointment_date
      appointment.start_time.strftime('%b %-d, %Y') if appointment?
    end

    def appointment_time_range
      return unless appointment?

      format = '%-l:%M %P'
      start = appointment.start_time.strftime(format).sub(':00', '')
      stop = appointment.stop_time.strftime(format).sub(':00', '')

      "#{start} - #{stop} (#{appointment.start_time.zone})"
    end

    def appointment_reading_room_name
      appointment.reading_room&.name if appointment?
    end
  end
end
