# frozen_string_literal: true

module Aeon
  # Render a group of requests that share the same title and request type
  class RequestGroupBriefComponent < Aeon::RequestGroupComponent
    with_collection_parameter :request_group

    def initialize(request_group:, heading_level: :h2)
      super(request_group:)
      @heading_level = heading_level
    end

    def title_tag
      style_class = @heading_level == :h3 ? 'h4' : 'h3'
      content_tag(@heading_level, title, class: style_class)
    end
  end
end
