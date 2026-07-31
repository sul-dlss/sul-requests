# frozen_string_literal: true

module Folio
  # card on requests page for displaying requests grouped by catkey
  class RequestGroupComponent < ViewComponent::Base
    with_collection_parameter :request_group

    attr_reader :request_group, :patron

    delegate :detail_link_to_searchworks, to: :helpers

    def initialize(request_group:, patron:)
      @request_group = request_group
      @patron = patron
      super()
    end
  end
end
