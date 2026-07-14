# frozen_string_literal: true

module Aeon
  # Render a single item row within a request group
  class RequestGroupItemComponent < ViewComponent::Base
    with_collection_parameter :request

    attr_reader :request, :classes

    delegate :transaction_number, :transaction_date, to: :request

    def initialize(request:, classes: %w[list-group-item request-grid], actions: true, fulfillment: true, remove_from_appointment: false, footer: true) # rubocop:disable Metrics/ParameterLists
      @request = request
      @classes = Array(classes)
      @actions = actions
      @fulfillment = fulfillment
      @remove_from_appointment = remove_from_appointment
      @footer = footer
    end

    def actions?
      @actions
    end

    def fulfillment?
      @fulfillment
    end

    def footer?
      @footer
    end

    def remove_from_appointment?
      @remove_from_appointment
    end
  end
end
