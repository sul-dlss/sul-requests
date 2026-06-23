# frozen_string_literal: true

module Folio
  # Render the checked out accruing amount
  class CheckedOutActionsComponent < ViewComponent::Base
    attr_reader :checkout

    delegate :sul_icon, to: :helpers

    def initialize(checkout:)
      @checkout = checkout
    end

    def accruing_rate_label
      rate = checkout.overdue_fines_rate
      return unless rate

      safe_join([sul_icon('sharp-warning-24px'), "Accruing #{number_to_currency(rate['quantity'])}/#{rate['intervalId']} until returned"])
    end

    def call
      tag.span(class: 'small fw-medium rounded-pill text-white bg-danger') do
        accruing_rate_label
      end
    end
  end
end
