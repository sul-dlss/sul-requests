# frozen_string_literal: true

module Aeon
  # Render an accordion item for a digitization form step.
  class DigitizationFormAccordionComponent < ViewComponent::Base
    attr_reader :title, :dom_id, :object, :base_name

    def initialize(title:, dom_id:, base_name: nil, object: nil, collapsed: true)
      @title = title
      @base_name = base_name
      @dom_id = dom_id
      @object = object
      @collapsed = collapsed
    end

    def collapsed?
      @collapsed
    end
  end
end
