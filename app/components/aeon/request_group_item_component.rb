# frozen_string_literal: true

module Aeon
  # Render a single item row within a request group
  class RequestGroupItemComponent < ViewComponent::Base
    with_collection_parameter :request

    attr_reader :request, :classes

    delegate :transaction_number, :transaction_date, to: :request

    def initialize(request:, classes: %w[list-group-item request-grid])
      @request = request
      @classes = Array(classes)
    end

    def request_sort_data
      {
        'default-sort-value': request.sort_key(:default),
        'title-sort-value': request.sort_key(:title),
        'date-sort-value': request.sort_key(:date)
      }
    end
  end
end
