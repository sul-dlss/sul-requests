# frozen_string_literal: true

module Aeon
  # Render an accordion item for a digitization form step.
  class RemoveRequestComponent < ViewComponent::Base
    def initialize(request:)
      @request = request
    end

    def spinner
      tag.div(class: 'text-green spinner-message align-content-center d-none', data: { submit_message_target: 'message' }) do
        tag.div(class: 'spinner-border spinner-border-sm me-2', aria: { hidden: true }) +
          tag.span('Removing and saving for later')
      end
    end

    def remove_button
      tag.button class: 'btn btn-link p-0 su-underline me-2 text-nowrap',
                 data: { action: 'click->add-items#remove click->submit-message#showMessage',
                         appointment_target: '#savedForLaterRequests',
                         submit_message_target: 'button',
                         transaction_number: @request.transaction_number,
                         title: @request.item_title } do
        tag.i(class: 'bi bi-pin-angle-fill me-1') + tag.span('Save for later')
      end
    end

    def call
      tag.span(class: 'actions', data: { controller: 'submit-message' }) do
        safe_join([remove_button, spinner])
      end
    end
  end
end
