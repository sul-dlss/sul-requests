# frozen_string_literal: true

module Aeon
  # Request item identifier
  class RequestItemIdentifierComponent < ViewComponent::Base
    attr_reader :request

    def initialize(request:)
      @request = request
    end

    def call_number
      call_number = request.call_number
      prefix = request.ead_number
      return call_number unless prefix.present? && call_number&.start_with?(prefix)

      call_number.delete_prefix(prefix)
    end

    def render?
      request.multi_item_selector?
    end
  end
end
