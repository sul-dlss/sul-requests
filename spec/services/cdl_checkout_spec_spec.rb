# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CdlCheckout do
  subject { described_class.new('druid', user) }

  let(:user) { create(:webauth_user) }
  let(:catalog_info) do
    instance_double(CatalogInfo,
      callkey: 'xyz',
      items: [
        instance_double(CatalogInfo, barcode: '12345', current_location: 'CDL-RESERVE')
      ]
    )
  end

  before do
    allow(user).to receive(:patron).and_return(Patron.new({}))
  end

  describe '#process_checkout' do
    it 'places the hold, checks the item out, and creates a token' do
      allow(CatalogInfo).to receive(:find).with('abc123').and_return(catalog_info)

      expect(subject.symphony_client).to receive(:place_hold)
      expect(subject.symphony_client).to receive(:check_out_item).with('12345', 'CDL-CHECKEDOUT').and_return(
        {
          'circRecord' => {
            'fields' => {
              'dueDate' => '2099-08-25T23:59:00-07:00'
            }
          }
        }
      )

      payload = subject.process_checkout('abc123')
      expect(payload).to include sub: user.webauth
    end
  end
end
