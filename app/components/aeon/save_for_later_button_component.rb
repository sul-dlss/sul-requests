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

    def form_element
      form_with(url: save_for_later_aeon_request_path(request)) do
        tag.button(type: :submit, class: 'btn btn-link su-underline text-nowrap',
                   data: { action: 'click->submit-message#showMessage',
                           submit_message_target: 'button' }) do
          tag.i(class: 'bi bi-pin-angle-fill align-middle me-1') + tag.span('Save for later')
        end
      end
    end

    def call
      tag.span(class: 'actions d-flex', data: { controller: 'submit-message' }) do
        safe_join([form_element, spinner])
      end
    end

    def spinner
      tag.div(class: 'px-2 py-1 text-green spinner-message align-content-center d-none', data: { submit_message_target: 'message' }) do
        tag.div(class: 'spinner-border spinner-border-sm me-2', aria: { hidden: true }) +
          tag.span('Removing and saving for later')
      end
    end
  end
end
