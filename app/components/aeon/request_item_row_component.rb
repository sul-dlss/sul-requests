# frozen_string_literal: true

module Aeon
  # Render a single request as a row inside a request group list
  class RequestItemRowComponent < ViewComponent::Base
    def initialize(request:, action_component: nil)
      @request = request
      @action_component = action_component
    end
  end
end
