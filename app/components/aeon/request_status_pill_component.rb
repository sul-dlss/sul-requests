# frozen_string_literal: true

module Aeon
  # Render request status pill (e.g., 'Reading room use')
  class RequestStatusPillComponent < ViewComponent::Base
    attr_reader :request

    delegate :appointment?, :completed?, :digital?, :draft?, :scan_delivered?, :submitted?, to: :request

    def initialize(request:)
      @request = request
    end

    def status_class
      if completed? || scan_delivered?
        :ready
      elsif submitted?
        appointment? ? :ready : :pending
      elsif draft?
        :draft
      else
        :cancelled
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

    def status_text
      reading_room || digitization_status
    end

    def digitization_status
      if scan_delivered?
        'Digitization ready'
      elsif submitted?
        'Digitization pending'
      else
        'Digitization'
      end
    end

    def reading_room
      'Reading room use' unless digital?
    end
  end
end
