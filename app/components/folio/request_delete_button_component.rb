# frozen_string_literal: true

module Folio
  # Trash-icon button that removes a request
  class RequestDeleteButtonComponent < ViewComponent::Base
    attr_reader :request

    def initialize(request:)
      @request = request
    end

    def request_type
      'Pickup'
    end

    def call_number
      request.full_call_number
    end

    def button_label
      "Delete #{request.title} request"
    end
  end
end
