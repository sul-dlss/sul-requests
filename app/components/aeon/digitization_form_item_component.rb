# frozen_string_literal: true

module Aeon
  # Render an accordion item for a digitization form step.
  class DigitizationFormItemComponent < ViewComponent::Base
    attr_reader :title, :dom_id, :object, :base_name

    def initialize(title:, dom_id:, object: nil, base_name: nil, collapsed: true)
      @title = title
      @dom_id = dom_id
      @object = object
      @base_name = base_name || "item[#{dom_id}]"
      @collapsed = collapsed
    end

    def collapsed?
      @collapsed
    end
  end
end
