# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::PayAllComponent, type: :component do
  let(:patron) do
    instance_double(Folio::Patron, key: '513a9054-5897-11ee-8c99-0242ac120002', fines:, can_pay_fines?: true)
  end

  let(:fines) do
    [
      instance_double(Folio::Account, owed: 3, key: '4085f2b-80f4-431d-ac3c-25cc2b62d4f6'),
      instance_double(Folio::Account, owed: 2, key: 'a4aedaea-1750-461e-b7bd-2c90ba6b95bc')
    ]
  end

  it 'renders a button' do
    render_inline(described_class.new(patron: patron))
    expect(page).to have_button 'Pay now'
  end

  context 'when the patron is e.g. blocked and unable to renew material' do
    before do
      allow(patron).to receive(:can_pay_fines?).and_return(false)
      render_inline(described_class.new(patron: patron))
    end

    it 'renders a disabled button' do
      expect(page).to have_css('button[disabled]', text: 'Payments blocked')
    end
  end
end
