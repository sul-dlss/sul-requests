# frozen_string_literal: true

module Aeon
  # Render an accordion item for a digitization form step.
  class RemoveRequestComponent < ViewComponent::Base
    def initialize(request:)
      @request = request
    end

    def call
      tag.button class: 'btn btn-link p-0 su-underline',
                 data: { action: 'click->add-items#remove',
                         appointment_target: '#draftRequests',
                         transaction_number: @request.transaction_number,
                         title: @request.item_title } do
        tag.i(class: 'bi bi-x') + tag.span('Remove')
      end
    end
  end
end
