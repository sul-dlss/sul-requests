# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmitFolioRequestJob do
  let(:client) { instance_double(FolioClient, create_circulation_request: double) }
  let(:patron) { Folio::Patron.new({ 'id' => patron_id, 'patronGroup' => patron_group_id, 'active' => true }) }
  let(:patron_id) { '562a5cb0-e998-4ea2-80aa-34ac2b536238' }
  let(:patron_group_id) { 'bdc2b6d4-5ceb-4a12-ab46-249b9a68473e' } # Undergrad

  before do
    skip "Must set Settings.ils.request_job=#{described_class}" unless Settings.ils.request_job == described_class.to_s
    allow(Request).to receive(:find).and_return(request)
    allow(FolioClient).to receive(:new).and_return(client)
  end

  context 'with a HoldRecall type request' do
    let(:best_request_type) { 'Recall' }
    let(:user) { create(:sequence_sso_user) }
    let(:item) do
      instance_double(Folio::Item, id: 'abc123-1-1', holdings_record_id: 'abc123-1', barcode: '12345678',
                                   status: 'Checked out', best_request_type:)
    end

    before do
      allow(request.user).to receive(:patron).and_return(patron)
      allow(request.bib_data).to receive(:items).and_return([item])
      allow(patron).to receive(:blocked?).and_return(false)
    end

    context 'with an sso user' do
      let(:request) { create(:hold_recall_with_holdings_folio, barcodes: ['12345678'], user:) }

      it 'places a recall for the item as the patron' do
        expect { described_class.perform_now(request.id) }.to change { request.folio_command_logs.count }.by(1)
        expect(client).to have_received(:create_circulation_request).with(
          have_attributes(
            request_type: 'Recall',
            requester_id: patron_id,
            item_id: 'abc123-1-1'
          )
        )
      end
    end

    context 'with a user without the recall ability' do
      let(:request) { create(:hold_recall_with_holdings_folio, barcodes: ['12345678'], user:) }
      let(:best_request_type) { 'Hold' }

      it 'places a hold for the item as the patron' do
        expect { described_class.perform_now(request.id) }.to change { request.folio_command_logs.count }.by(1)
        expect(client).to have_received(:create_circulation_request).with(
          have_attributes(
            request_type: 'Hold',
            requester_id: patron_id,
            item_id: 'abc123-1-1'
          )
        )
      end
    end

    context 'without barcode (title request)' do
      let(:request) { create(:hold_on_order, barcodes: [], user:) }

      before do
        allow(client).to receive(:create_instance_hold)
      end

      it 'places a title-level hold for the instance as the patron' do
        described_class.perform_now(request.id)
        expect(client).to have_received(:create_instance_hold)
          .with(patron_id, 'a43e597a-d4b4-50ec-ad16-7fd49920831a', FolioClient::HoldRequest)
      end
    end

    context 'with an sso user with no patron group' do
      let(:best_request_type) { 'Hold' }
      let(:user) { create(:sso_user) }
      let(:request) { create(:hold_recall_with_holdings_folio, barcodes: ['12345678'], user:) }
      let(:patron_group_id) { nil }
      let(:pseudopatron) { instance_double(Folio::Patron, id: 'HOLD@GR-PSEUDO', patron_group_id:, blocked?: false) }

      before do
        allow(Folio::Patron).to receive(:find_by).with(library_id: 'HOLD@GR').and_return(pseudopatron)
      end

      it 'places a hold for the item as a pseudopatron with patron comment' do
        described_class.perform_now(request.id)
        expect(client).to have_received(:create_circulation_request).with(
          have_attributes(
            request_type: 'Hold',
            requester_id: 'HOLD@GR-PSEUDO',
            item_id: 'abc123-1-1',
            patron_comments: 'Some SSO User <some-sso-user@stanford.edu>'
          )
        )
      end
    end
  end

  context 'with a Page type request' do
    let(:best_request_type) { 'Page' }
    let(:user) { create(:sequence_sso_user) }
    let(:item) do
      instance_double(Folio::Item, id: 'abc123-1-1', holdings_record_id: 'abc123-1', barcode: '3610512345678',
                                   status: 'Available', best_request_type:)
    end
    let(:request) { create(:page_with_holdings, barcodes: ['3610512345678'], user:) }

    before do
      allow(request.user).to receive(:patron).and_return(patron)
      allow(request.bib_data).to receive(:items).and_return([item])
    end

    context 'with an sso user in good standing' do
      before do
        allow(patron).to receive(:blocked?).and_return(false)
      end

      it 'places a page request for the item as the patron' do
        described_class.perform_now(request.id)
        expect(client).to have_received(:create_circulation_request).with(
          have_attributes(
            request_type: 'Page',
            requester_id: patron_id,
            item_id: 'abc123-1-1'
          )
        )
      end
    end

    context 'with an sso user who has blocks' do
      before do
        allow(patron).to receive(:blocked?).and_return(true)
      end

      it 'places a page request for the item as the patron' do
        described_class.perform_now(request.id)
        expect(client).to have_received(:create_circulation_request).with(
          have_attributes(
            request_type: 'Page',
            requester_id: patron_id,
            item_id: 'abc123-1-1'
          )
        )
        expect(request.ils_response.usererr_code).to eq 'u003'
      end
    end

    context 'with a non-sso user' do
      let(:user) { create(:non_sso_user) }
      let(:patron) { nil }

      before do
        allow(Folio::Patron).to receive(:find_by).with(library_id: 'HOLD@AR').and_return(
          instance_double(Folio::Patron, id: 'HOLD@AR-PSEUDO', patron_group_id:, blocked?: false)
        )
      end

      it 'places a page request for the item using a pseudopatron with patron comments' do
        described_class.perform_now(request.id)
        expect(client).to have_received(:create_circulation_request).with(
          have_attributes(
            request_type: 'Page',
            requester_id: 'HOLD@AR-PSEUDO',
            item_id: 'abc123-1-1',
            patron_comments: 'Jane Stanford <jstanford@stanford.edu>'
          )
        )
      end
    end

    context 'with an sso user with no patron group' do
      let(:user) { create(:sso_user) }
      let(:patron_group_id) { nil }

      before do
        allow(Folio::Patron).to receive(:find_by).with(library_id: 'HOLD@AR').and_return(
          instance_double(Folio::Patron, id: 'HOLD@AR-PSEUDO', patron_group_id:, blocked?: false)
        )
      end

      it 'places a page request for the item using a pseudopatron with patron comments' do
        described_class.perform_now(request.id)
        expect(client).to have_received(:create_circulation_request).with(
          have_attributes(
            request_type: 'Page',
            requester_id: 'HOLD@AR-PSEUDO',
            item_id: 'abc123-1-1',
            patron_comments: 'Some SSO User <some-sso-user@stanford.edu>'
          )
        )
      end
    end

    context 'with a mix of failing and successful request items' do
      let(:request) { create(:page_with_single_holding_multiple_items, barcodes: ['12345678', '12345679'], user:) }
      let(:command) { described_class::Command.new(request, logger: Rails.logger) }
      let(:item) do
        instance_double(Folio::Item, id: 'abc123-1-2', holdings_record_id: 'abc123-1', barcode: '12345679',
                                     status: 'Available', best_request_type:)
      end

      before do
        allow(patron).to receive(:blocked?).and_return(false)
      end

      it 'receives only one circulation request if the other results in error' do
        described_class.perform_now(request.id)
        # only one request should be successful
        expect(client).to have_received(:create_circulation_request).once
      end

      it 'returns error msgcode for a circulation request with an error' do
        circ_request = command.send(:create_item_circulation_request, '12345678')
        expect(circ_request).to include(barcode: '12345678', msgcode: '456')
      end
    end
  end

  context 'with a MediatedPage type request' do
    let(:best_request_type) { 'Page' }
    let(:request) do
      create(
        :mediated_page_with_holdings,
        user:,
        barcodes: ['34567890'],
        created_at: 1.day.from_now,
        needed_date: Time.zone.now
      )
    end
    let(:item) do
      instance_double(Folio::Item, id: 'abc123-1-1', holdings_record_id: 'abc123-1', barcode: '34567890', status: 'Available',
                                   best_request_type:)
    end

    before do
      allow(request.user).to receive(:patron).and_return(patron)
      allow(request.bib_data).to receive(:items).and_return([item])
    end

    context 'with a non-sso user' do
      let(:user) { create(:non_sso_user, name: 'Jim Doe', email: 'jimdoe@example.com') }
      let(:patron) { nil }

      before do
        allow(Folio::Patron).to receive(:find_by).with(library_id: 'HOLD@AR').and_return(
          instance_double(Folio::Patron, id: 'HOLD@AR-PSEUDO', patron_group_id:, blocked?: false)
        )
      end

      it 'places a page request for the item as a pseudopatron with patron comments' do
        expect { described_class.perform_now(request.id) }.to change { request.folio_command_logs.count }.by(1)
        expect(client).to have_received(:create_circulation_request).with(
          have_attributes(
            request_type: 'Page',
            requester_id: 'HOLD@AR-PSEUDO',
            item_id: 'abc123-1-1',
            patron_comments: 'Jim Doe <jimdoe@example.com>'
          )
        )
      end
    end

    context 'with an sso user with no patron group' do
      let(:user) { create(:sso_user) }
      let(:patron_group_id) { nil }

      before do
        allow(patron).to receive(:blocked?).and_return(false)
        allow(Folio::Patron).to receive(:find_by).with(library_id: 'HOLD@AR').and_return(
          instance_double(Folio::Patron, id: 'HOLD@AR-PSEUDO', patron_group_id:, blocked?: false)
        )
        allow(request.bib_data).to receive(:items).and_return([item])
      end

      it 'places a page request for the item as a pseudopatron with patron comments' do
        described_class.perform_now(request.id)
        expect(client).to have_received(:create_circulation_request).with(
          have_attributes(
            request_type: 'Page',
            requester_id: 'HOLD@AR-PSEUDO',
            item_id: 'abc123-1-1',
            patron_comments: 'Some SSO User <some-sso-user@stanford.edu>'
          )
        )
      end
    end
  end

  context 'with a Scan type request' do
    context 'with a non-sso user' do
      let(:best_request_type) { 'Hold' }
      let(:user) { create(:non_sso_user, name: 'Jim Doe', email: 'jimdoe@example.com') }
      let(:patron) { nil }
      let(:request) do
        create(:scan, :with_holdings_barcodes, origin: 'SAL', origin_location: 'SAL-TEMP', bib_data: build(:scannable_only_holdings), user:)
      end
      let(:item) do
        instance_double(Folio::Item, id: 'abc123-1-1', holdings_record_id: 'abc123-1', barcode: '12345678', status: 'Available',
                                     best_request_type:)
      end

      before do
        allow(Folio::Patron).to receive(:find_by).with(library_id: 'GRE-SCANDELIVER').and_return(
          instance_double(Folio::Patron, id: 'GRE-SCANDELIVER', patron_group_id:, blocked?: false)
        )
        allow(request.bib_data).to receive(:items).and_return([item])
      end

      it 'places a hold request for the item as a pseudopatron with patron comments' do
        described_class.perform_now(request.id)
        expect(client).to have_received(:create_circulation_request).with(
          have_attributes(
            request_type: 'Hold',
            requester_id: 'GRE-SCANDELIVER',
            item_id: 'abc123-1-1',
            patron_comments: 'Jim Doe <jimdoe@example.com>'
          )
        )
      end
    end
  end

  context 'with a proxy request (Page)' do
    let(:best_request_type) { 'Page' }
    let(:user) { create(:sequence_sso_user) }
    let(:request) { create(:page_with_holdings, barcodes: ['3610512345678'], user:, proxy: true) }
    let(:proxy_id) { '562a5cb0-e998-4ea2-80aa-34ac2b536238' }
    let(:sponsor_id) { '2bd36e69-1f58-4f6b-9073-e8d932edeed2' }
    let(:item) do
      instance_double(Folio::Item, id: 'abc123-1-1', holdings_record_id: 'abc123-1', barcode: '3610512345678', status: 'Available',
                                   best_request_type:)
    end

    before do
      allow(Folio::Patron).to receive(:find_by).and_return(patron)
      allow(client).to receive(:proxy_info).and_return(proxy_response)
      allow(patron).to receive(:blocked?).and_return(false)
      allow(request.bib_data).to receive(:items).and_return([item])
    end

    context 'as the proxy user' do
      let(:patron) { Folio::Patron.new({ 'id' => proxy_id, 'active' => true, 'patronGroup' => patron_group_id }) }
      let(:proxy_response) { { 'userId' => sponsor_id } }

      it 'places a page request as the sponsor user with a proxy pickup comment' do
        described_class.perform_now(request.id)
        expect(client).to have_received(:create_circulation_request).with(
          have_attributes(
            request_type: 'Page',
            requester_id: sponsor_id,
            patron_comments: /PROXY PICKUP OK/
          )
        )
      end
    end

    context 'as the sponsor' do
      let(:patron) { Folio::Patron.new({ 'id' => sponsor_id, 'active' => true, 'patronGroup' => patron_group_id }) }
      let(:proxy_response) { {} }

      it 'places a page request as the sponsor user with a proxy pickup comment' do
        described_class.perform_now(request.id)
        expect(client).to have_received(:create_circulation_request).with(
          have_attributes(
            request_type: 'Page',
            requester_id: sponsor_id,
            patron_comments: /PROXY PICKUP OK/
          )
        )
      end
    end
  end
end
