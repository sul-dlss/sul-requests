# frozen_string_literal: true

module Aeon
  # Trash-icon button that removes a request from its activity
  class RemoveFromActivityButtonComponent < ViewComponent::Base
    attr_reader :request

    def initialize(request:)
      @request = request
    end

    def render?
      helpers.can?(:destroy, request)
    end

    def call
      form_with(url: aeon_request_path(request), method: :delete) do
        tag.button(type: :submit, class: 'btn btn-link su-underline') do
          tag.i(class: 'bi bi-trash align-middle me-1', aria: { hidden: true }) + tag.span('Remove from activity', class: 'visually-hidden')
        end
      end
    end
  end
end
