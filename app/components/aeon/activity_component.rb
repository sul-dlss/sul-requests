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
  end
end
