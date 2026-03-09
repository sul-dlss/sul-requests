# frozen_string_literal: true

module Aeon
  # Render request status information about missing fields/requirements
  class RequestStatusMessageComponent < ViewComponent::Base
    attr_reader :request

    delegate :digital?, :draft?, to: :request

    def initialize(request:)
      @request = request
    end

    def render?
      status_message.present?
    end

    def status_level
      return unless draft?

      :warning
    end

    def status_message
      return unless draft?

      if digital?
        'Pages/instructions not specified'
      else
        'Not scheduled'
      end
    end
  end
end
