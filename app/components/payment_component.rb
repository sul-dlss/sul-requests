# frozen_string_literal: true

# Paid accounts
class PaymentComponent < ViewComponent::Base
  attr_reader :payment, :patron

  delegate :detail_link_to_searchworks, to: :helpers

  def initialize(payment:, patron:)
    @payment = payment
    @patron = patron
    super()
  end
end
