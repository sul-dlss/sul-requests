# frozen_string_literal: true

module Aeon
  # Render an accordion item for a digitization form step.
  class DigitizationFormItemComponent < ViewComponent::Base
    attr_reader :base_name, :object

    def initialize(base_name: nil, object: nil)
      @base_name = base_name || "item[#{dom_id}]"
      @object = object
    end
  end
end
