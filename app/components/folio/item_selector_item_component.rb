# frozen_string_literal: true

module Folio
  # Component for rendering an item selector for a specific item
  class ItemSelectorItemComponent < ViewComponent::Base
    with_collection_parameter :item

    attr_reader :item, :f

    def initialize(item:, item_counter:, f:, render_location: false) # rubocop:disable Naming/MethodParameterName
      @item = item
      @item_counter = item_counter
      @f = f
      @render_location = render_location
      super()
    end

    def index
      @item_counter + 1
    end

    def not_requestable?
      helpers.cannot?(:request, item)
    end

    def render_location?
      @render_location
    end

    def item_label # rubocop:disable Metrics/AbcSize
      status_class = item.checked_out? || not_requestable? ? 'unavailable' : item.status_class
      status_text = if not_requestable?
                      item.status_text == 'Not requestable' ? item.status_text : "Not requestable / #{item.status_text}"
                    else
                      item.status_text
                    end
      due_date = item.checked_out? ? tag.span("Due #{item.due_date}", class: 'ms-1 text-danger') : ''
      content_tag :span, class: "status availability #{status_class}" do
        helpers.availability_bootstrap_icon(status_class) + status_text + due_date
      end
    end
  end
end
