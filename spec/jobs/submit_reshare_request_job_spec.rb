# frozen_string_literal: true

require 'rails_helper'

describe SubmitReshareRequestJob, type: :job do
  let(:user) { create(:library_id_user) }
  let(:patron) { instance_double(Symphony::Patron, exists?: true, email: nil, university_id: '1234567') }
  let(:request) { create(:hold_recall_with_holdings, user: user) }
  let(:sw_item) { double('SeachWorksItem', isbn: %w[12345 54321]) }

  before do
    Sidekiq.logger.level = Logger::UNKNOWN
    allow(Symphony::Patron).to receive(:find_by).with(library_id: user.library_id).and_return(patron)
    allow(request).to receive(:bib_data).and_return(sw_item)
  end

  describe '#perform' do
    let(:reshare_vufind_item) { double('ReshareVufindWrapper') }

    before do
      expect(SubmitReshareRequestJob::ReshareVufindWrapper).to receive(:new).with(request).and_return(
        reshare_vufind_item
      )
    end

    context 'when the patron does not have a university ID' do
      before do
        allow(patron).to receive(:university_id).and_return(nil)
      end

      it 'sends the request to Symphony' do
        expect(Request.ils_job_class).to receive(:perform_now).with(request.id, {})

        subject.perform(request.id)
      end
    end

    context 'when the item is not requestable in BorrowDirect' do
      before { expect(reshare_vufind_item).to receive(:requestable?).and_return(false) }

      it 'sends the request off to the ILS (without attempting to request it)' do
        expect(reshare_vufind_item).not_to receive(:request_item)
        expect(Request.ils_job_class).to receive(:perform_now).with(request.id, {})

        subject.perform(request.id)
      end
    end

    context 'when the item request in BorrowDirect throws an error' do
      before do
        expect(reshare_vufind_item).to receive(:requestable?).and_raise('The API Error')
      end

      it 'sends the request off to the ILS and notifies Honeybadger' do
        expect(Honeybadger).to receive(:notify).with(
          'Reshare Request failed for 1 with The API Error. Submitted to the ILS instead.'
        )
        expect(Request.ils_job_class).to receive(:perform_now).with(request.id, {})

        subject.perform(request.id)
      end
    end

    context 'when the item is requestable and the request succeeds' do
      before do
        expect(reshare_vufind_item).to receive_messages(
          requestable?: true,
          instance_uuid: '12345',
          instance_title: 'A title',
          as_json: { 'mockResponse' => ['Successful Response'], 'RequestNumber' => '1' }
        )

        allow(SubmitIplcListenerJob).to receive(:perform_later)
      end

      it 'persists the BorrowDirect response' do
        subject.perform(request.id)

        expect(request.reload.reshare_vufind_response_data).to eq(
          'mockResponse' => ['Successful Response'], 'RequestNumber' => '1'
        )
      end

      it 'sets the via_borrow_direct? flag to true' do
        subject.perform(request.id)

        expect(request.reload).to be_via_borrow_direct
      end

      it 'enqueues the request to IPLC' do
        subject.perform(request.id)

        expect(SubmitIplcListenerJob).to have_received(:perform_later).with(request.id, '12345', 'A title')
      end
    end
  end

  describe SubmitReshareRequestJob::ReshareVufindWrapper do
    subject(:reshare_vufind_item) { described_class.new(request) }

    describe '#requestable?' do
      context 'when the SearchWorksItem does not have an ISBN' do
        before { expect(sw_item).to receive(:isbn).and_return(nil) }

        it do
          expect(subject).not_to be_requestable
        end
      end

      context 'when the SearchWorksItem has an ISBN but the item is not findable in BorrowDirect' do
        before do
          stub_request(:get, %r{#{Settings.borrow_direct.reshare_vufind_url}/api/v1/search})
            .with(query: hash_including(lookfor: '12345'))
            .to_return(body: '{"total":0}')
        end

        it do
          expect(subject).not_to be_requestable
        end
      end

      context 'when the SearchWorksItem has an ISBN but the item is not available in BorrowDirect' do
        before do
          stub_request(:get, %r{#{Settings.borrow_direct.reshare_vufind_url}/api/v1/search})
            .with(query: hash_including(lookfor: '12345'))
            .to_return(body: '{"total":1,"records":[{"lendingStatus":["NONLENDABLE"]}]}')
        end

        it do
          expect(subject).not_to be_requestable
        end
      end

      context 'when the SearchWorksItem has an ISBN and the item is available in BorrowDirect' do
        before do
          stub_request(:get, %r{#{Settings.borrow_direct.reshare_vufind_url}/api/v1/search})
            .with(query: hash_including(lookfor: '12345'))
            .to_return(body: '{"total":1,"records":[{"id":"12345", "lendingStatus":["LOANABLE"]}]}')
        end

        it do
          expect(subject).to be_requestable.and have_attributes(instance_uuid: '12345')
        end
      end
    end
  end
end
