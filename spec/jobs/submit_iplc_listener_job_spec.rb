# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmitIplcListenerJob, type: :job do
  let(:user) { create(:library_id_user) }
  let(:request) { create(:hold_recall_with_holdings, user:) }
  let(:sw_item) { double('SeachWorksItem', isbn: %w[12345 54321]) }

  before do
    Sidekiq.logger.level = Logger::UNKNOWN
    allow(Symphony::Patron).to receive(:find_by).with(library_id: user.library_id).at_least(:once).and_return(
      double(exists?: true, email: 'patron@example.com')
    )
    allow(request).to receive(:bib_data).and_return(sw_item)
  end

  describe '#perform' do
    let(:iplc_response_item) { double('IplcWrapper') }

    before do
      expect(SubmitIplcListenerJob::IplcWrapper).to receive(:new).with(request, 'iplc-uuid', 'iplc-title').and_return(
        iplc_response_item
      )
    end

    context 'when the item request in BorrowDirect throws an error' do
      before do
        expect(iplc_response_item).to receive(:success?).and_raise('The API Error')
      end

      it 'sends the request off to Symphony and notifies Honeybadger' do
        expect(Honeybadger).to receive(:notify).with(
          'IPLC Request failed for 1 with The API Error. Submitted to the ILS instead.'
        )
        expect(Request.ils_job_class).to receive(:perform_now).with(request.id, {})

        subject.perform(request.id, 'iplc-uuid', 'iplc-title')
      end
    end

    context 'when the item is requestable and the request succeeds' do
      before do
        allow(Request.ils_job_class).to receive(:perform_now)
        expect(iplc_response_item).to receive_messages(
          success?: true,
          as_json: { 'mockResponse' => ['Successful Response'], 'RequestNumber' => '1' }
        )

        allow(described_class).to receive(:perform_later)
      end

      it 'persists the BorrowDirect response' do
        subject.perform(request.id, 'iplc-uuid', 'iplc-title')

        expect(request.reload.borrow_direct_response_data).to eq(
          'mockResponse' => ['Successful Response'], 'RequestNumber' => '1'
        )
      end

      it 'sets the via_borrow_direct? flag to true' do
        subject.perform(request.id, 'iplc-uuid', 'iplc-title')

        expect(request.reload).to be_via_borrow_direct
      end

      it 'sends the approval status email' do
        expect(RequestStatusMailer).to receive(
          :request_status_for_holdrecall
        )

        subject.perform(request.id, 'iplc-uuid', 'iplc-title')
      end
    end
  end

  describe SubmitIplcListenerJob::IplcWrapper do
    subject(:iplc_request) { described_class.new(request, 'iplc-uuid', 'iplc-title') }

    let(:iplc_params) do
      {
        req_id: 'university-id',
        'res.org': 'ISIL:US-CST',
        rfr_id: 'gid://sul-requests/HoldRecall/1',
        rft_id: 'iplc-uuid',
        'rft.title': 'iplc-title',
        'svc.pickupLocation': 'STA_GREEN',
        svc_id: 'json'
      }
    end

    before do
      stub_request(:get, Settings.borrow_direct.iplc_listener_url)
        .with(query: iplc_params)
        .to_return(iplc_return)
      allow(user.patron).to receive(:university_id).and_return('university-id')
    end

    context 'when the request is successful' do
      let(:iplc_return) { { body: '{"response":{"status":201}}' } }

      it do
        expect(subject).to be_success
      end

      it 'includes the response' do
        expect(JSON.parse(subject.to_json)['response']).to eq({ 'response' => { 'status' => 201 } })
      end

      it 'includes the params with Symphony to ReShare converted pickup location code' do
        expect(JSON.parse(subject.to_json)['params']['svc.pickupLocation']).to eq('STA_GREEN')
      end
    end

    context 'when the request is not successful' do
      let(:iplc_return) { { status: 400 } }

      it do
        expect(subject).not_to be_success
      end
    end
  end
end
