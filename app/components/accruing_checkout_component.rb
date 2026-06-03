# frozen_string_literal: true

# Render an overdue checkout that is accruing fines on the fines page
class AccruingCheckoutComponent < ViewComponent::Base
  attr_reader :checkout, :patron

  delegate :sul_icon, :detail_link_to_searchworks, to: :helpers

  def initialize(checkout:, patron:)
    @checkout = checkout
    @patron = patron
    super()
  end

  def accruing_rate_label
    rate = checkout.overdue_fines_rate
    return unless rate

    "Accruing #{number_to_currency(rate['quantity'])}/#{rate['intervalId']} until returned"
  end
end
