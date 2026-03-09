# frozen_string_literal: true

module Aeon
  # Render request card
  class RequestComponent < ViewComponent::Base
    attr_reader :request

    delegate :appointment, :appointment?, :call_number, :date, :document_type,
             :draft?, :title, :transaction_date, :transaction_number, :transaction_status, to: :request

    def initialize(request:)
      @request = request
    end

    def appointment_date
      appointment.start_time.strftime('%b %-d, %Y') if appointment?
    end

    def show_appointment?
      appointment? && !draft?
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

    def thumbnail?
      # TODO: fill in data
      [true, false].sample
    end
  end
end
