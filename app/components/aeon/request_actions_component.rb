# frozen_string_literal: true

module Aeon
  # Render request actions
  class RequestActionsComponent < ViewComponent::Base
    attr_reader :request

    def initialize(request:)
      @request = request
    end

    def render?
      !request.completed?
    end

    def include_bulk_actions?
      @request.saved_for_later? && helpers.can?(:destroy, request)
    end
  end
end
