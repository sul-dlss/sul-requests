# frozen_string_literal: true

module Folio
  class FineComponentPreview < ViewComponent::Preview
    layout 'lookbook'

    def default
      render Folio::FineComponent.new(
        fine: FactoryBot.build(:checkout, loan_policy: FactoryBot.build(:grad_mono_loans),
                                          overdue_fines_policy: FactoryBot.build(:overdue_fine_policy_daily)),
        patron: FactoryBot.build(:sponsor_patron)
      )
    end
  end
end
