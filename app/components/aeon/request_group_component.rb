# frozen_string_literal: true

module Aeon
  # Render request card
  class RequestGroupComponent < ViewComponent::Base
    attr_reader :request_group

    def initialize(request_group:)
      @request_group = request_group
    end

    def one?
      request_group.requests.size == 1
    end

    def first_request
      request_group.requests.first
    end
  end
end
