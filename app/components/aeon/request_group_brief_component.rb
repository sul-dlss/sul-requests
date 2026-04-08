# frozen_string_literal: true

module Aeon
  # Render a group of requests that share the same title and request type
  class RequestGroupBriefComponent < Aeon::RequestGroupComponent
    with_collection_parameter :request_group

    def initialize(classes: 'request-group border rounded p-3 mb-3', **)
      super(**)
      @classes = classes
    end
  end
end
