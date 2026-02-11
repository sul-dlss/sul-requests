# frozen_string_literal: true

module Aeon
  # Render request card
  class RequestComponent < ViewComponent::Base
    attr_reader :request

    delegate :appointment?, :appointment, :aeon_link, :pages, :volume, :format, :title, :date, :document_type, :call_number,
             :transaction_status, :transaction_date, :transaction_number, to: :request

    def initialize(request:)
      @request = request
    end

    def searchworks_link
      return unless aeon_link&.include?('searchworks')

      aeon_link
    end

    def format_info
      return "Pages: #{pages}" if pages
      return "Item: #{volume}" if volume
      return "Format: #{format}" if format

      nil
    end

    def status_text
      return 'Reading room appointment' if appointment?

      status = Aeon::Status.find_by(id: transaction_status)
      status['Web Display Name'] || status['Name']
    end

    def complete?
      # There will be additional logic here.
      appointment?
    end

    def status
      return :completed if complete?

      :pending
    end

    def status_icon
      case status
      when :pending
        'clock'
      when :completed
        'check2-circle'
      end
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

    def thumbnail?
      # TODO: fill in data
      [true, false].sample
    end
  end
end
