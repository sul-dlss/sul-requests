# frozen_string_literal: true

module Aeon
  # Render a compact view of a group of requests that share the same title and request type
  class RequestGroupCompactComponent < Aeon::RequestGroupComponent
    with_collection_parameter :request_group
  end
end
