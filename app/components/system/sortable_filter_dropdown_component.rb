# frozen_string_literal: true

module System
  # Render sort dropdown
  class SortableFilterDropdownComponent < ViewComponent::Base
    attr_reader :button_label

    renders_many :list_items, lambda { |label:, field:|
      tag.li do
        tag.button(class: 'dropdown-item', data: {
                     action: 'click->sortable#filter',
                     sortable_filter_param: field,
                     sortable_label_param: label
                   }) do
          label
        end
      end
    }

    def initialize(button_label: 'All requests')
      @button_label = button_label
    end
  end
end
