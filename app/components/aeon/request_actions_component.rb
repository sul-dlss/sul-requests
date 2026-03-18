# frozen_string_literal: true

module Aeon
  # Render request actions
  class RequestActionsComponent < ViewComponent::Base
    attr_reader :request

    delegate :appointment, :digital?, :title, :transaction_number, to: :request

    def initialize(request:)
      @request = request
    end

    def request_type
      if digital?
        'Digitization'
      else
        'Reading room use'
      end
    end

    def include_bulk_actions
      @request.draft? && (helpers.can? :edit, @request)
    end
  end
end
