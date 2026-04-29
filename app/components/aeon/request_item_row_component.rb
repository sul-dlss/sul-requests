# frozen_string_literal: true

module Aeon
  # Render a single request as a row inside a request group list
  class RequestItemRowComponent < ViewComponent::Base
    def initialize(request:, after_component: nil)
      @request = request
      @after_component = after_component
    end
  end
end
