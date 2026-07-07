# frozen_string_literal: true

module Folio
  # Render the checked out accruing amount
  class CheckedOutActionsComponent < ViewComponent::Base
    attr_reader :checkout

    def initialize(checkout:)
      @checkout = checkout
    end

    def accruing_rate_label
      rate = checkout.overdue_fines_rate
      return unless rate

      safe_join([tag.i(class: 'bi bi-exclamation-triangle me-2'),
                 "Accruing #{number_to_currency(rate['quantity'])}/#{rate['intervalId']} until returned"])
    end

    def call
      tag.span(class: 'fw-bold rounded-pill text-digital-red-dark bg-digital-red-10 text-nowrap') do
        accruing_rate_label
      end
    end
  end
end
