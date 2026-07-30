# frozen_string_literal: true

module System
  # Render a delete button with confirmation modal
  class DeleteWithConfirmationComponent < ViewComponent::Base
    renders_one :body

    attr_reader :id, :button_label, :form_url

    def initialize(id:, form_url:, button_label: 'Delete')
      @id = id
      @button_label = button_label
      @form_url = form_url
    end
  end
end
