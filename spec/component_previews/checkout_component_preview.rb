# frozen_string_literal: true

class CheckoutComponentPreview < ViewComponent::Preview
  layout 'lookbook'

  def default
    render CheckoutComponent.new(
      checkout: FactoryBot.build(:checkout, loan_policy: FactoryBot.build(:grad_mono_loans)),
      patron: FactoryBot.build(:sponsor_patron)
    )
  end

  def recall
    render CheckoutComponent.new(
      checkout: FactoryBot.build(:checkout_with_recall, loan_policy: FactoryBot.build(:grad_mono_loans)),
      patron: FactoryBot.build(:sponsor_patron)
    )
  end

  def overdue
    render CheckoutComponent.new(
      checkout: FactoryBot.build(:overdue_checkout, loan_policy: FactoryBot.build(:grad_mono_loans)),
      patron: FactoryBot.build(:sponsor_patron)
    )
  end
end
