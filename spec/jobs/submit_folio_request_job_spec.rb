# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmitFolioRequestJob do
  let(:user) { create(:sequence_sso_user) }
  let(:client) { instance_double(FolioClient, get_item: { 'id' => 4 }, get_service_point: { 'id' => 5 }, create_item_hold: double) }
  let(:expected_date) { DateTime.now.beginning_of_day.utc.iso8601 }

  before do
    allow(Request).to receive(:find).and_return(request)
    allow(FolioClient).to receive(:new).and_return(client)
  end

  context 'with a HoldRecall type request' do
    let(:request) { create(:hold_recall_with_holdings, barcodes: ['12345678'], user:) }

    context 'with an sso user' do
      let(:patron) { instance_double(Folio::Patron, id: '562a5cb0-e998-4ea2-80aa-34ac2b536238') }

      before do
        allow(request.user).to receive(:patron).and_return(patron)
      end

      it 'calls the create_item_hold API method' do
        described_class.perform_now(request.id)
        expect(client).to have_received(:create_item_hold).with('562a5cb0-e998-4ea2-80aa-34ac2b536238', 4, FolioClient::HoldRequest)
      end
    end
  end

  context 'with a MediatedPage type request' do
    context 'with a non-sso user' do
      let(:request) do
        create(
          :mediated_page_with_holdings,
          user: create(:non_sso_user, name: 'Jim Doe ', email: 'jimdoe@example.com'),
          barcodes: %w(34567890),
          created_at: 1.day.from_now,
          needed_date: Time.zone.now
        )
      end

      it 'calls the create_item_hold API method' do
        described_class.perform_now(request.id)
        expect(client).to have_received(:create_item_hold).with('2bd36e69-1f58-4f6b-9073-e8d932edeed2', 4, FolioClient::HoldRequest)
      end
    end
  end

  context 'with a Scan type request' do
    context 'with a non-sso user' do
      let(:request) do
        create(:scan, :with_holdings_barcodes, user: create(:sso_user))
      end

      it 'calls the create_item_hold API method' do
        described_class.perform_now(request.id)
        # once for each barcode
        expect(client).to have_received(:create_item_hold).with('0ba81714-52d4-4f37-8b4d-f9d929af048d', 4, FolioClient::HoldRequest).twice
      end
    end
  end
end
