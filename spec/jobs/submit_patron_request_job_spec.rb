# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmitPatronRequestJob do
  let(:patron) do
    instance_double(Folio::Patron, id: 'patron_id', username: 'username', blocked?: false, ilb_eligible?: true,
                                   allowed_request_types: ['Hold', 'Recall', 'Page'])
  end
  let(:request) { PatronRequest.new(instance_hrid: 'a12345', patron:, barcodes: ['12345678'], origin_location_code: 'SAL3-STACKS') }
  let(:bib_data) { build(:single_holding) }

  before do
    stub_bib_data_json(bib_data)
    allow(SubmitIlliadPatronRequestJob).to receive(:perform_now).and_return('illiad_response')
    allow(SubmitFolioPatronRequestJob).to receive(:perform_now).and_return('folio_response')
  end

  context 'when the request is sent to FOLIO' do
    before do
      allow(request).to receive(:request_type).and_return('page')
    end

    it 'stores FOLIO data in the request' do
      described_class.perform_now(request)
      expect(request.folio_responses).to eq(bib_data.items[0].id => 'folio_response')
    end
  end

  context 'when the request is sent to ILLiad' do
    before do
      allow(request).to receive(:request_type).and_return('scan')
    end

    it 'stores ILLiad data in the request' do
      described_class.perform_now(request)
      expect(request.illiad_response_data).to eq(bib_data.items[0].id => 'illiad_response')
    end
  end

  context 'when the request is a scan' do
    before do
      allow(request).to receive(:request_type).and_return('scan')
    end

    it 'requests items via ILLiad' do
      described_class.perform_now(request)
      expect(SubmitIlliadPatronRequestJob).to have_received(:perform_now).with(request, bib_data.items[0].id)
    end
  end

  context 'when the request is a page' do
    before do
      allow(request).to receive(:request_type).and_return('page')
    end

    it 'requests items via FOLIO' do
      described_class.perform_now(request)
      expect(SubmitFolioPatronRequestJob).to have_received(:perform_now).with(request, bib_data.items[0].id)
    end
  end

  context 'when the patron is not ILB eligible' do
    before do
      allow(patron).to receive(:ilb_eligible?).and_return(false)
    end

    it 'requests items via FOLIO' do
      described_class.perform_now(request)
      expect(SubmitFolioPatronRequestJob).to have_received(:perform_now).with(request, bib_data.items[0].id)
    end
  end

  context 'when the item is a recall' do
    before do
      allow(request).to receive_messages(request_type: 'recall', fulfillment_type: 'recall')
    end

    context 'when the item has a recallable status' do
      before do
        allow(bib_data.items[0]).to receive(:status).and_return(Folio::Item::STATUS_IN_PROCESS)
      end

      it 'requests items via FOLIO' do
        described_class.perform_now(request)
        expect(SubmitFolioPatronRequestJob).to have_received(:perform_now).with(request, bib_data.items[0].id)
      end
    end

    context 'when the item is not in an easily recallable status' do
      before do
        allow(bib_data.items[0]).to receive(:status).and_return(Folio::Item::STATUS_MISSING)
      end

      it 'requests items via ILLiad' do
        described_class.perform_now(request)
        expect(SubmitIlliadPatronRequestJob).to have_received(:perform_now).with(request, bib_data.items[0].id)
      end
    end

    context 'when the item has a request queue' do
      it 'requests items via ILLiad', pending: 'https://github.com/sul-dlss/sul-requests/issues/2234'
    end
  end
end