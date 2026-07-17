# frozen_string_literal: true

# Render sort dropdown
class SortableDropdownComponent < ViewComponent::Base
  attr_reader :button_label

  renders_many :list_items, lambda { |label:, field:|
    tag.li do
      tag.button(class: 'dropdown-item', data: {
                   action: 'click->sortable#sort',
                   sortable_sort_param: field,
                   sortable_label_param: "Sort by #{label}"
                 }) do
        label
      end
    end
  }

  def initialize(button_label: 'Sort by')
    @button_label = button_label
  end
end
