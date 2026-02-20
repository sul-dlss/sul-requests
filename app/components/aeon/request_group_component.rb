# frozen_string_literal: true

module Aeon
  # Render request card
  class RequestGroupComponent < ViewComponent::Base
    attr_reader :request_group

    delegate :requests, to: :request_group

    delegate :item_url, :title, :date, :document_type, :call_number, :transaction_number, :submitted?, :digital?, :physical?,
             to: :first_request

    def initialize(request_group:)
      @request_group = request_group
    end

    def one?
      requests.size == 1
    end

    def first_request
      requests.first
    end

    def searchworks_url
      return unless item_url&.include?('searchworks')

      item_url
    end

    def status_text
      if digital?
        return 'Digitization ready' if all_completed?
        return 'Digitization pending' if any_submitted?

        return 'Digitization'
      end

      'Reading room use'
    end

    def status_class
      if all_completed?
        :ready
      elsif any_submitted?
        :pending
      else
        :draft
      end
    end

    def status_icon
      case status_class
      when :pending
        'clock'
      when :ready
        'check2-circle'
      end
    end

    def format_info(request)
      return "Pages: #{request.pages}" if request.pages
      return "Item: #{request.volume}" if request.volume
      return "Format: #{request.format}" if request.format

      nil
    end

    def all_completed?
      requests.all?(&:completed?) || requests.all?(&:scan_delivered?)
    end

    def any_submitted?
      requests.any?(&:submitted?)
    end

    def editable?
      requests.any? { |x| x.appointment&.editable? }
    end

    def appointment_date(request)
      request.appointment.start_time.strftime('%b %-d, %Y') if request.appointment?
    end

    def appointment_time_range(request)
      return unless request.appointment?

      format = '%-l:%M %P'
      start = request.appointment.start_time.strftime(format).sub(':00', '')
      stop = request.appointment.stop_time.strftime(format).sub(':00', '')

      "#{start} - #{stop} (#{request.appointment.start_time.zone})"
    end

    def appointment_reading_room_name
      first_request.appointment.reading_room&.name if first_request.appointment?
    end

    def thumbnail?
      # TODO: fill in data
      [true, false].sample
    end

    def transaction_date
      requests.filter_map(&:transaction_date).max
    end
  end
end
