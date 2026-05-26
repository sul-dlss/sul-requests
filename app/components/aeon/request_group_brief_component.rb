# frozen_string_literal: true

module Aeon
  # Render a group of requests that share the same title and request type
  class RequestGroupBriefComponent < Aeon::RequestGroupComponent
    with_collection_parameter :request_group

    attr_reader :classes

    def initialize(after_request_item_component: nil, classes: %w[request-group border rounded p-3], data: {}, **)
      @after_request_item_component = after_request_item_component
      @classes = Array(classes)
      @data = data
      super(**)
    end

    def data
      { title: }.merge(@data)
    end
  end
end
