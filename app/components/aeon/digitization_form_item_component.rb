# frozen_string_literal: true

module Aeon
  # Render an accordion item for a digitization form step.
  class DigitizationFormItemComponent < ViewComponent::Base
    attr_reader :title, :dom_id, :object, :base_name

    def initialize(title:, dom_id:, object: nil, base_name: nil, single_item: false)
      @title = title
      @dom_id = dom_id
      @object = object
      @base_name = base_name || "item[#{dom_id}]"
      @single_item = single_item
    end

    def single_item?
      @single_item
    end

    def button_attributes
      attrs = {
        class: 'accordion-button d-inline-flex w-auto align-items-center position-static',
        type: 'button',
        'data-bs-toggle': 'collapse',
        'data-bs-target': "#content_#{dom_id}",
        'aria-expanded': single_item? ? 'true' : 'false',
        'aria-controls': "content_#{dom_id}"
      }
      attrs[:disabled] = true if single_item?
      attrs
    end
  end
end
