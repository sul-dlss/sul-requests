# frozen_string_literal: true

module Aeon
  # Render a single request as a row inside a request group list, optionally
  # with an action (add, remove, etc.) shown after the identifier.
  class RequestItemRowComponent < ViewComponent::Base
    def initialize(request:, action: nil)
      @request = request
      @action = action
    end
  end
end
