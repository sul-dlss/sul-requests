# frozen_string_literal: true

module Home
  # Generic count-with-link card for the card-view home page.
  class SummaryCardComponent < ViewComponent::Base
    attr_reader :title, :icon, :count, :item_label, :item_label_suffix, :empty_label, :path, :status,
                :empty_path, :empty_link_label, :next_up_date,
                :secondary_count, :secondary_label, :secondary_label_suffix

    # rubocop:disable Metrics/ParameterLists, Metrics/MethodLength
    def initialize(title:, icon:, count:, item_label:, empty_label:, path:,
                   item_label_suffix: nil, status: nil, empty_path: nil, empty_link_label: nil,
                   next_up_date: nil, secondary_count: nil, secondary_label: nil, secondary_label_suffix: nil)
      # rubocop:enable Metrics/ParameterLists, Metrics/MethodLength
      @title = title
      @icon = icon
      @count = count
      @item_label = item_label
      @item_label_suffix = item_label_suffix
      @empty_label = empty_label
      @path = path
      @status = status
      @empty_path = empty_path
      @empty_link_label = empty_link_label
      @next_up_date = next_up_date
      @secondary_count = secondary_count
      @secondary_label = secondary_label
      @secondary_label_suffix = secondary_label_suffix
    end

    def empty?
      count.to_i.zero?
    end
  end
end
