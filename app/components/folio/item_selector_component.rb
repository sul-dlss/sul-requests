# frozen_string_literal: true

module Folio
  # Component for rendering an item selector for an instance
  class ItemSelectorComponent < ViewComponent::Base
    attr_reader :f

    delegate :sort_holdings, to: :helpers

    def initialize(f:) # rubocop:disable Naming/MethodParameterName
      @f = f
      super()
    end

    def items
      @items ||= sort_holdings(f.object.selectable_items)
    end

    def render_search?
      items.length >= 10
    end
  end
end
