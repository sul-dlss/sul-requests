# frozen_string_literal: true

module Aeon
  # Render a single item row within a request group
  class RequestGroupItemComponent < ViewComponent::Base
    with_collection_parameter :request

    attr_reader :request

    delegate :transaction_number, :transaction_date, to: :request

    def initialize(request:, actions: true, appointment: true, remove_from_appointment: false, footer: true)
      @request = request
      @actions = actions
      @appointment = appointment
      @remove_from_appointment = remove_from_appointment
      @footer = footer
    end

    def actions?
      @actions
    end

    def appointment?
      @appointment
    end

    def footer?
      @footer
    end

    def remove_from_appointment?
      @remove_from_appointment
    end
  end
end
