# frozen_string_literal: true

module Aeon
  # Render aeon remove/save for later button
  class CancelOrSaveForLaterButtonComponent < ViewComponent::Base
    attr_reader :request

    def initialize(request:)
      @request = request
    end

    def call
      return remove_button if request.activity?

      save_for_later_button
    end

    private

    def remove_button
      form_with(url: aeon_request_path(request, kind: request.request_type), method: :delete) do
        tag.button(type: :submit, class: 'btn btn-link su-underline') do
          tag.i(class: 'bi bi-trash align-middle me-1')
        end
      end
    end

    def save_for_later_button
      form_with(url: redraft_aeon_request_path(request, kind: request.request_type)) do
        tag.button(type: :submit, class: 'btn btn-link su-underline') do
          tag.i(class: 'bi bi-pin-angle-fill align-middle me-1') + tag.span('Save for later')
        end
      end
    end
  end
end
