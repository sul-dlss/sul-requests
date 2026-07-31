# frozen_string_literal: true

module System
  # Component for rendering a grouped request item layout.
  class GroupedRequestItemLayoutComponent < ViewComponent::Base
    renders_one :identifier
    renders_one :detail
    renders_one :fulfillment
    renders_one :actions
    renders_one :footer

    attr_reader :request_id, :date, :classes, :attr, :element

    def initialize(request_id: nil, date: nil, classes: [], element: :li, **attr)
      @element = element
      @request_id = request_id
      @date = date
      @classes = classes
      @attr = attr

      super()
    end
  end
end
