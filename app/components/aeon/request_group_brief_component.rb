# frozen_string_literal: true

module Aeon
  # Render a group of requests that share the same title and request type
  class RequestGroupBriefComponent < Aeon::RequestGroupComponent
    with_collection_parameter :request_group

    def initialize(item_action: nil, data: {}, **)
      @item_action = item_action
      @data = data
      super(**)
    end

    def data
      { controller: 'empty-remove', title: }.merge(@data)
    end
  end
end
