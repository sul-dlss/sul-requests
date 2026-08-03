# frozen_string_literal: true

module Aeon
  # Render aeon activity card
  class ActivityComponent < ViewComponent::Base
    attr_reader :activity

    def initialize(activity:, requests: false)
      @activity = activity
      @requests = requests
    end

    def requests?
      @requests
    end

    def sort_filter_params
      {
        date_sort_value: activity.sort_key(:date),
        name_sort_value: activity.sort_key(:name),
        activity_type_sort_value: activity.sort_key(:activity_type),
        filter_value: activity.activity_type
      }
    end
  end
end
