# frozen_string_literal: true

module Aeon
  # Render request status information about missing fields/requirements
  class RequestStatusMessageComponent < ViewComponent::Base
    attr_reader :request

    delegate :saved_for_later?, :digital?, to: :request

    def initialize(request:)
      @request = request
    end

    def render?
      saved_for_later?
    end

    def status_message
      if digital?
        'Pages/instructions not specified'
      else
        'Not scheduled'
      end
    end
  end
end
