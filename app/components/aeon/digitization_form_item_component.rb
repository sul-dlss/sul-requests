# frozen_string_literal: true

module Aeon
  # Render an accordion item for a digitization form step.
  class DigitizationFormItemComponent < ViewComponent::Base
    attr_reader :title, :dom_id, :object, :base_name

    def initialize(title:, dom_id:, object: nil, base_name: nil, accordion: true)
      @title = title
      @dom_id = dom_id
      @object = object
      @base_name = base_name || "item[#{dom_id}]"
      @accordion = accordion
    end

    def accordion?
      @accordion
    end
  end
end
