# frozen_string_literal: true

module Aeon
  class DailyItemLimitComponentPreview < ViewComponent::Preview
    layout 'lookbook'

    # @!group Variations
    def zero
      render Aeon::DailyItemLimitComponent.new(count: 0, limit: 5)
    end

    def a_few
      render Aeon::DailyItemLimitComponent.new(count: 3, limit: 5)
    end

    def near_max
      render Aeon::DailyItemLimitComponent.new(count: 4, limit: 5)
    end

    def at_max
      render Aeon::DailyItemLimitComponent.new(count: 5, limit: 5)
    end

    def beyond_the_max
      render Aeon::DailyItemLimitComponent.new(count: 9, limit: 5)
    end

    def large_limit
      render Aeon::DailyItemLimitComponent.new(count: 76, limit: 100)
    end
    # @!endgroup
  end
end
