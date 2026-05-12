# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'fines/index' do
  let(:fine) do
    instance_double(Folio::Account,
                    owed: 3,
                    status: 'A',
                    nice_status: 'Damaged',
                    bib?: true,
                    key: 'abc',
                    bill_date: Date.new,
                    fee: 5,
                    library_name: 'Best Lib',
                    library_code: 'BLIB',
                    barcode: '12345',
                    author: 'Author 1',
                    title: 'Title',
                    shelf_key: 'AB 1234',
                    call_number: 'AB 1234',
                    catkey: '12345',
                    patron_key: 'patronkey123',
                    instance_of?: Folio::Account)
  end
  let(:fines) { [fine] }
  let(:checkouts) do
    [Folio::Checkout.new(
      { 'id' => '31d15973-acb6-4a12-92c7-5e2d5f2470ed',
        'item' => { 'title' => 'Mental growth during the first three years' },
        'overdue' => true,
        'details' => { 'feesAndFines' => { 'amountRemainingToPay' => 10 } } },
      '3684a786-6671-4268-8ed0-9db82ebca60b'
    )]
  end
  let(:patron) do
    instance_double(Folio::Patron,
                    key: '1',
                    fines:,
                    can_pay_fines?: true,
                    requests: [],
                    checkouts: [],
                    remaining_checkouts: nil,
                    barred?: false,
                    status: 'OK',
                    sponsor?: false,
                    display_name: 'Shea Sponsor',
                    instance_of?: Folio::Patron)
  end
  let(:patron_or_group) { patron }

  context 'when the patron is not in a group' do
    before do
      assign(:fines, fines)
      assign(:checkouts, checkouts)
      without_partial_double_verification do
        allow(view).to receive_messages(patron_or_group: patron, patron:)
      end
    end

    it 'shows the fined item author' do
      render
      expect(rendered).to have_text('Author 1')
    end

    it 'shows the Pay button' do
      render
      expect(rendered).to have_text('Pay $3.00 now')
    end

    context 'when the patron has accruing fines' do
      it 'shows the accrued amount' do
        render
        expect(rendered).to have_text('Accruing: $10.00')
      end
    end
  end
end
