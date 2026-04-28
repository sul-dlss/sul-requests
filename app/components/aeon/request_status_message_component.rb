# frozen_string_literal: true

module Aeon
  # Render request status information about missing fields/requirements
  class RequestStatusMessageComponent < ViewComponent::Base
    attr_reader :request

    delegate :cancelled?, :digital?, :draft?, :physical?, :scan_delivered?, to: :request

    def initialize(request:)
      @request = request
    end

    def render?
      status_message.present?
    end

    def status_level
      if draft?
        :warning
      elsif digital? && !scan_delivered?
        :pending
      else
        :ready
      end
    end

    def status_message
      draft_status_message
    end

    def draft_status_message
      return unless draft?

      if digital?
        'Pages/instructions not specified'
      else
        'Not scheduled'
      end
    end
  end
end
