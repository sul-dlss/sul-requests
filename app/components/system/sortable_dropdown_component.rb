# frozen_string_literal: true

module System
  # Render sort dropdown
  class SortableDropdownComponent < ViewComponent::Base
    attr_reader :active_label

    renders_many :list_items, lambda { |label:, field:|
      tag.li do
        tag.button(class: classes(label), data: {
                     action: 'click->sortable#sort',
                     sortable_sort_param: field,
                     sortable_label_param: "Sort by #{label}"
                   }) do
          label
        end
      end
    }

    def classes(label)
      return 'dropdown-item active' if active_label == label

      'dropdown-item'
    end

    def dropdown_id
      return "#{@prepend_id}DropdownFilterMenuLink" if @prepend_id

      'dropdownFilterMenuLink'
    end

    def initialize(active_label: '', prepend_id: nil)
      @active_label = active_label
      @prepend_id = prepend_id
    end
  end
end
