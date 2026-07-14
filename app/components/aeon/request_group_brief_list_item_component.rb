# frozen_string_literal: true

module Aeon
  # Render a group of requests in li element
  class RequestGroupBriefListItemComponent < ViewComponent::Base
    with_collection_parameter :request

    attr_reader :classes, :request

    def initialize(request: [], after_request_item_component: nil, additional_classes: [])
      @after_request_item_component = after_request_item_component
      @classes = %w[request list-group-item] + Array(additional_classes)
      @request = request
    end
  end
end
