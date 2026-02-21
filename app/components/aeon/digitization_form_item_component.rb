# frozen_string_literal: true

module Aeon
  # Render an accordion item for a digitization form step.
  class DigitizationFormItemComponent < ViewComponent::Base
    attr_reader :title, :dom_id, :base_name, :series, :subseries

    def initialize(title:, dom_id:, base_name: nil, series: nil, subseries: nil)
      @title = title
      @dom_id = dom_id
      @base_name = base_name || "item[#{dom_id}]"
      @series = series
      @subseries = subseries
    end
  end
end
