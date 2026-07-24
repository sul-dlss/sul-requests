# frozen_string_literal: true

module Aeon
  # Render an add item button for add items modal
  class AddRequestComponent < ViewComponent::Base
    def initialize(request:)
      @request = request
    end

    def spinner
      tag.div(class: 'text-green spinner-message align-content-center d-none', data: { submit_message_target: 'message' }) do
        tag.div(class: 'spinner-border spinner-border-sm me-2', aria: { hidden: true }) +
          tag.span('Scheduling....')
      end
    end

    def add_request
      tag.button class: 'btn btn-link p-0 su-underline me-2 text-nowrap',
                 data: { action: 'click->add-items#schedule
                                  item-limit-updated@window->add-items#enableDisableButton
                                  click->submit-message#showMessage',
                         transaction_number: @request.transaction_number,
                         submit_message_target: 'button',
                         appointment_target: '#appointmentRequests',
                         title: @request.item_title } do
        tag.i(class: 'bi bi-plus-lg me-1') + tag.span('Add to appointment')
      end
    end

    def call
      tag.span(class: 'actions', data: { controller: 'submit-message' }) do
        safe_join([add_request, spinner])
      end
    end
  end
end
