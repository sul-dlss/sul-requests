# frozen_string_literal: true

module Folio
  class CheckoutComponentPreview < ViewComponent::Preview
    layout 'lookbook'

    def default
      render Folio::CheckoutComponent.new(
        checkout: FactoryBot.build(:checkout, loan_policy: FactoryBot.build(:grad_mono_loans)),
        patron: FactoryBot.build(:sponsor_patron)
      )
    end

    def recall
      render Folio::CheckoutComponent.new(
        checkout: FactoryBot.build(:checkout_with_recall, loan_policy: FactoryBot.build(:grad_mono_loans)),
        patron: FactoryBot.build(:sponsor_patron)
      )
    end

    def overdue
      checkout = FactoryBot.build(:overdue_checkout, loan_policy: FactoryBot.build(:grad_mono_loans))
      checkout.define_singleton_method(:overdue_fines_policy_id) do
        '12d0d55b-bcb9-473e-9bd7-1a54d52c007f'
      end
      render Folio::CheckoutComponent.new(
        checkout:,
        patron: FactoryBot.build(:sponsor_patron)
      )
    end
  end
end
