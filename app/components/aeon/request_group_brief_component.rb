# frozen_string_literal: true

module Aeon
  # Render a group of requests that share the same title and request type
  class RequestGroupBriefComponent < Aeon::RequestGroupComponent
    with_collection_parameter :request_group

    def initialize(after_request_item_component: nil, data: {}, **)
      @after_request_item_component = after_request_item_component
      @data = data
      super(**)
    end

    def data
      { controller: 'empty-remove', title: }.merge(@data)
    end
  end
end
