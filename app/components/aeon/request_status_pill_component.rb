# frozen_string_literal: true

module Aeon
  # Render request status pill (e.g., 'Reading room use')
  class RequestStatusPillComponent < ViewComponent::Base
    attr_reader :request

    delegate :appointment?, :digital?, :status, to: :request

    def initialize(request:)
      @request = request
    end

    def status_class
      case status
      when :completed
        :ready
      when :submitted
        appointment? ? :ready : :pending
      else
        status
      end
    end

    def status_icon
      case status_class
      when :pending
        'bi bi-clock'
      when :ready
        'bi bi-check2-circle'
      end
    end

    def status_text
      reading_room || digitization_status
    end

    def digitization_status
      return unless digital?

      case status
      when :completed
        'Digitization ready'
      when :submitted
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
