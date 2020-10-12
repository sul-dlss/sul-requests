# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CdlCheckout do
  subject { described_class.new('druid', user) }

  let(:user) { create(:webauth_user) }
  let(:catalog_info) do
    instance_double(CatalogInfo,
                    callkey: 'xyz',
                    cdl_proxy_hold_item: instance_double(CatalogInfo, key: '1'),
                    loan_period: 2.hours,
                    items: items)
  end
  let(:symphony_client) { instance_double(SymphonyClient) }

  let(:items) do
    [
      instance_double(CatalogInfo, barcode: '12345',
                                   cdlable?: true,
                                   current_location: 'CDL-RESERVE')
    ]
  end

  before do
    allow(user).to receive(:patron).and_return(Patron.new({}))
    allow(SymphonyClient).to receive(:new).and_return(symphony_client)
  end

  describe '#process_checkout' do
    # rubocop:disable RSpec/EmptyExampleGroup
    context 'with an existing hold and associated checkout' do
      pending 'gives you the active token'
    end

    context 'with an existing hold' do
      pending 'updates the existing hold the the checkout'
    end

    context 'when all eligible items are in use' do
      pending 'places a hold and renders something about a waitlist'
    end

    context 'when there is a choice if eligible items' do
      pending 'places a hold and picks one of the items using some criteria'
    end
    # rubocop:enable RSpec/EmptyExampleGroup

    it 'places the hold, checks the item out, and creates a token' do
      allow(CatalogInfo).to receive(:find).with('abc123').and_return(catalog_info)

      expect(symphony_client).to receive(:place_hold).and_return({})
      expect(symphony_client).to receive(:check_out_item).with('12345', 'CDL-CHECKEDOUT', dueDate: anything).and_return(
        {
          'circRecord' => {
            'fields' => {
              'dueDate' => '2099-08-25T23:59:00-07:00'
            }
          }
        }
      )
      expect(symphony_client).to receive(:update_hold).and_return({})

      payload = subject.process_checkout('abc123')
      expect(payload[:token]).to include sub: user.webauth
    end
  end
end
