# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::CheckoutComponent, type: :component do
  before do
    allow(checkout).to receive(:overdue_fines_policy_id).and_return(overdue_fines_policy_id)
    render_inline(described_class.new(checkout:, patron:))
  end

  let(:patron) { build(:sponsor_patron) }
  let(:checkout) { build(:checkout, loan_policy:) }
  let(:loan_policy) { build(:grad_mono_loans) }
  let(:overdue_fines_policy_id) { '' }

  context 'when proxy has checked out item' do
    it 'shows proxy badge' do
      expect(page).to have_css('.status-pill', text: 'Proxy')
    end

    it 'shows name of borrower' do
      expect(page).to have_text('Borrowed by: Piper Proxy')
    end
  end

  context 'when there is a recalled checkout' do
    let(:checkout) { build(:checkout_with_recall, loan_policy:) }

    it 'shows recalled badge' do
      expect(page).to have_css('.status-pill', text: 'Recalled')
    end

    it 'shows recall message' do
      expect(page).to have_text('This item was requested by another user. Please return as soon as possible.')
    end
  end

  context 'when the checkout is not renewable' do
    let(:loan_policy) { build(:reserves_loan_policy) }

    it 'does not show a renew button' do
      expect(page).to have_no_button('Renew', disabled: :all)
    end
  end

  context 'when it is too soon to renew the checkout' do
    let(:loan_policy) do
      policy = build(:grad_mono_loans).loan_policy.deep_merge('loansPolicy' => { 'fixedDueDateSchedule' => nil })
      Folio::LoanPolicy.new(loan_policy: policy)
    end

    it 'shows the reason next to the due date' do
      expect(page).to have_css('.card-header .text-digital-red-dark', text: 'Too soon to renew')
    end
  end

  context 'when a checkout is overdue' do
    let(:checkout) { build(:overdue_checkout, loan_policy:) }
    let(:overdue_fines_policy_id) { '12d0d55b-bcb9-473e-9bd7-1a54d52c007f' }

    it 'shows recalled badge' do
      expect(page).to have_css('.status-pill', text: 'Overdue')
    end

    it 'shows overdue message' do
      expect(page).to have_text('Accruing $1.00/day until returned')
    end
  end
end
