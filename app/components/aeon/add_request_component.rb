# frozen_string_literal: true

module Aeon
  # Render an add item button for add items modal
  class AddRequestComponent < ViewComponent::Base
    def initialize(request:)
      @request = request
    end

    def call
      tag.button class: 'btn btn-link p-0 su-underline',
                 data: { action: 'click->add-items#schedule',
                         transaction_number: @request.transaction_number,
                         item_limit_updated_target: 'addButton',
                         appointment_target: '#appointmentRequests',
                         title: @request.item_title } do
        tag.i(class: 'bi bi-plus') + tag.span('Add to appointment')
      end
    end
  end
end
