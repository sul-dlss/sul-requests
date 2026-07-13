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
        status.to_s.dasherize
      end
    end

    def status_text
      if digital?
        'Digitization'
      else
        'Reading room use'
      end
    end
  end
end
