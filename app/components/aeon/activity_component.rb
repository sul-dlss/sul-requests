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

    def item_pill
      if requests?
        return PillComponent.new(classes: %w[bg-stanford-20-black px-2
                                             text-stanford-black]).with_content(pluralize(activity.requests.length, 'item'))
      end

      PillComponent.new(id: dom_id(activity, :item_pill), classes: %w[placeholder placeholder-glow px-2]).with_content('Loading')
    end
  end
end
