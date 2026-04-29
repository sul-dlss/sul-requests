# frozen_string_literal: true

module Aeon
  # Render a compact view of a group of requests for bulk actions.
  class RequestGroupBulkActionsComponent < Aeon::RequestGroupComponent
    with_collection_parameter :request_group

    attr_reader :hidden

    def initialize(request_group:, hidden: true)
      super(request_group:)
      @hidden = hidden
    end
  end
end
