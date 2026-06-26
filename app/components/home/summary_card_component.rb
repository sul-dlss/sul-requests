# frozen_string_literal: true

module Home
  # Generic count-with-link card for the card-view home page.
  class SummaryCardComponent < ViewComponent::Base
    attr_reader :id, :title, :icon, :label, :count, :path, :status,
                :empty_path, :empty_link_label, :next_up_date, :secondary_label

    # rubocop:disable Metrics/ParameterLists
    def initialize(id:, title:, icon:, path:, count:, label: nil, secondary_label: nil, status: nil, empty_path: nil, empty_link_label: nil,
                   next_up_date: nil)
      # rubocop:enable Metrics/ParameterLists
      @id = id
      @title = title
      @icon = icon
      @count = count
      @label = label
      @secondary_label = secondary_label
      @path = path
      @status = status
      @empty_path = empty_path
      @empty_link_label = empty_link_label
      @next_up_date = next_up_date
    end

    def empty?
      count.to_i.zero?
    end
  end
end
