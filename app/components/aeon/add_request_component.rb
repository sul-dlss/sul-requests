# frozen_string_literal: true

module Aeon
  # Render an accordion item for a digitization form step.
  class AddRequestComponent < ViewComponent::Base
    def initialize(request:)
      @request = request
    end

    def call
      tag.button 'Add', class: 'btn btn-link p-0',
                        data: { action: 'click->add-items#schedule',
                                transaction_number: @request.transaction_number,
                                title: @request.item_title }
    end
  end
end
