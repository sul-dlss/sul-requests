# frozen_string_literal: true

module Aeon
  # Render a request's appointment time
  class RequestAppointmentTimeComponent < ViewComponent::Base
    attr_reader :request

    delegate :appointment, :appointment?, :cancelled?, :completed?, :saved_for_later?, to: :request

    def initialize(request:, with_reading_room: true)
      @request = request
      @with_reading_room = with_reading_room
    end

    def render?
      appointment? && !saved_for_later?
    end

    def appointment_date
      l(appointment.start_time, format: :date_only) if appointment?
    end

    def appointment_time_range
      return if !appointment? || appointment.reading_room.day_only_appointments?

      start = l(appointment.start_time, format: :time_only).sub(':00', '')
      stop = l(appointment.stop_time, format: :time_only).sub(':00', '')

      "#{start} - #{stop} (#{appointment.start_time.zone})"
    end

    def appointment_reading_room_name
      appointment.reading_room&.name if appointment?
    end

    def text_color_class
      cancelled? || completed? ? 'text-80-black' : 'text-green'
    end
  end
end
