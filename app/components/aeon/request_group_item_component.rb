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

    def fulfillment_mode
      return if request.saved_for_later?

      return :cancelled if request.cancelled_by_staff?
      return :appointment if request.appointment?

      if request.digital? # rubocop:disable Style/GuardClause
        return :ready if request.scan_delivered?

        :pending if request.submitted?
      end
    end
  end
end
