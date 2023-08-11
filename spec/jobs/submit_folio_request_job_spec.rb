# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmitFolioRequestJob do
  before do
    skip "Must set Settings.ils.request_job=#{described_class}" unless Settings.ils.request_job == described_class.to_s
    allow(Request).to receive(:find).and_return(request)
    allow(FolioClient).to receive(:new).and_return(client)
  end

  let(:client) { instance_double(FolioClient, get_item: { 'id' => 4 }, ice_point: { 'id' => 5 }, create_item_hold: double) }
  let(:expected_date) { DateTime.now.beginning_of_day.utc.iso8601 }

  context 'with a HoldRecall type request' do
    let(:user) { create(:sequence_sso_user) }
    let(:patron) { Folio::Patron.new({ 'id' => '562a5cb0-e998-4ea2-80aa-34ac2b536238' }) }

    before do
      allow(request.user).to receive(:patron).and_return(patron)
      allow(patron).to receive(:blocked?).and_return(false)
    end

    context 'with an sso user' do
      let(:request) { create(:hold_recall_with_holdings_folio, barcodes: ['12345678'], user:) }

      it 'calls the create_item_hold API method' do
        expect { described_class.perform_now(request.id) }.to change { request.folio_command_logs.count }.by(1)
        expect(client).to have_received(:create_item_hold).with('562a5cb0-e998-4ea2-80aa-34ac2b536238', 4, FolioClient::HoldRequest)
      end
    end

    context 'without barcode (title request)' do
      before do
        allow(client).to receive(:create_instance_hold)
      end

      let(:request) { create(:hold_on_order, barcodes: [], user:) }

      it 'calls the create_instance_hold API method' do
        described_class.perform_now(request.id)
        expect(client).to have_received(:create_instance_hold).with('562a5cb0-e998-4ea2-80aa-34ac2b536238',
                                                                    'a43e597a-d4b4-50ec-ad16-7fd49920831a', FolioClient::HoldRequest)
      end
    end
  end

  context 'with a Page type request' do
    let(:request) { create(:page_with_holdings, barcodes: ['3610512345678'], user:) }

    context 'with an sso user in good standing' do
      let(:user) { create(:sequence_sso_user) }
      let(:patron) { Folio::Patron.new({ 'id' => '562a5cb0-e998-4ea2-80aa-34ac2b536238', 'active' => true }) }

      before do
        allow(request.user).to receive(:patron).and_return(patron)
        allow(patron).to receive(:blocked?).and_return(false)
      end

      it 'calls the create_item_hold API method' do
        described_class.perform_now(request.id)
        expect(client).to have_received(:create_item_hold).with('562a5cb0-e998-4ea2-80aa-34ac2b536238', 4, FolioClient::HoldRequest)
      end
    end

    context 'with an sso user who has blocks' do
      let(:user) { create(:sequence_sso_user) }
      let(:patron) { Folio::Patron.new({ 'id' => '562a5cb0-e998-4ea2-80aa-34ac2b536238', 'active' => true }) }

      before do
        allow(request.user).to receive(:patron).and_return(patron)
        allow(patron).to receive(:blocked?).and_return(true)
      end

      it 'calls the create_item_hold API method' do
        described_class.perform_now(request.id)
        expect(client).to have_received(:create_item_hold).with('562a5cb0-e998-4ea2-80aa-34ac2b536238', 4, FolioClient::HoldRequest)
        expect(request.ils_response.usererr_code).to eq 'u003'
      end
    end

    context 'with a non-sso user' do
      let(:user) { create(:non_sso_user) }

      before do
        allow(request.user).to receive(:patron).and_return(nil)
      end

      it 'calls the create_item_hold API method' do
        described_class.perform_now(request.id)
        expect(client).to have_received(:create_item_hold) do |id, item_id, request|
          expect(id).to eq '2bd36e69-1f58-4f6b-9073-e8d932edeed2'
          expect(item_id).to eq 4
          expect(request.patron_comments).to eq 'Jane Stanford <jstanford@stanford.edu>'
        end
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
        expect { described_class.perform_now(request.id) }.to change { request.folio_command_logs.count }.by(1)
        expect(client).to have_received(:create_item_hold).with('2bd36e69-1f58-4f6b-9073-e8d932edeed2', 4, FolioClient::HoldRequest)
      end
    end
  end

  context 'with a Scan type request' do
    context 'with a non-sso user' do
      let(:request) do
        create(:scan, :with_holdings_barcodes, origin: 'SAL', origin_location: 'SAL-TEMP', bib_data: build(:scannable_only_holdings),
                                               user: create(:sso_user))
      end

      it 'calls the create_item_hold API method' do
        expect { described_class.perform_now(request.id) }.to change { request.folio_command_logs.count }.by(2)
        # once for each barcode
        expect(client).to have_received(:create_item_hold).with('0ba81714-52d4-4f37-8b4d-f9d929af048d', 4, FolioClient::HoldRequest).twice
      end
    end
  end

  context 'with a proxy request' do
    let(:request) { create(:page_with_holdings, barcodes: ['3610512345678'], user:, proxy: true) }

    context 'with a proxy user' do
      let(:user) { create(:sequence_sso_user) }
      let(:proxy_id) { '562a5cb0-e998-4ea2-80aa-34ac2b536238' }
      let(:sponsor_id) { '2bd36e69-1f58-4f6b-9073-e8d932edeed2' }
      let(:patron) { Folio::Patron.new({ 'id' => proxy_id, 'active' => true }) }

      let(:proxy_response) do
        {
          'userId' => sponsor_id
        }
      end

      before do
        allow_any_instance_of(Request).to receive(:user).and_return(user)
        allow(user).to receive(:patron).and_return(patron)
        allow(patron).to receive(:blocked?).and_return(false)
        allow(client).to receive(:proxy_info).with(proxy_id).and_return(proxy_response)
      end

      it 'calls the create_item_hold API method' do
        described_class.perform_now(request.id)
        expect(client).to have_received(:create_item_hold).with(sponsor_id, 4, have_attributes(patron_comments: /PROXY PICKUP OK/))
      end
    end

    context 'with the sponsor' do
      let(:user) { create(:sequence_sso_user) }
      let(:sponsor_id) { '2bd36e69-1f58-4f6b-9073-e8d932edeed2' }
      let(:patron) { Folio::Patron.new({ 'id' => sponsor_id, 'active' => true }) }
      let(:proxy_response) do
        {}
      end

      before do
        allow_any_instance_of(Request).to receive(:user).and_return(user)
        allow(user).to receive(:patron).and_return(patron)
        allow(patron).to receive(:blocked?).and_return(false)
        allow(client).to receive(:proxy_info).with(sponsor_id).and_return(proxy_response)
      end

      it 'calls the create_item_hold API method' do
        described_class.perform_now(request.id)
        expect(client).to have_received(:create_item_hold).with(sponsor_id, 4, have_attributes(patron_comments: /PROXY PICKUP OK/))
      end
    end
  end
end
