# frozen_string_literal: true

module Aeon
  # Pin-icon button to save a request for later
  class SaveForLaterButtonComponent < ViewComponent::Base
    attr_reader :request

    def initialize(request:)
      @request = request
    end

    def render?
      helpers.can?(:update, request)
    end

    def call
      form_with(url: save_for_later_aeon_request_path(request)) do
        tag.button(type: :submit, class: 'btn btn-link su-underline text-nowrap') do
          tag.i(class: 'bi bi-pin-angle-fill align-middle me-1') + tag.span('Save for later')
        end
      end
    end
  end
end
