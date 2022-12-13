# frozen_string_literal: true

require 'rails_helper'

describe SubmitIplcListenerJob, type: :job do
  let(:user) { create(:library_id_user) }
  let(:request) { create(:hold_recall_with_holdings, user: user) }
  let(:sw_item) { double('SeachWorksItem', isbn: %w[12345 54321]) }

  before do
    Sidekiq.logger.level = Logger::UNKNOWN
    allow(Patron).to receive(:find_by).with(library_id: user.library_id).at_least(:once).and_return(
      double(exists?: true, email: 'patron@example.com')
    )
    allow(request).to receive(:searchworks_item).and_return(sw_item)
  end

  describe '#perform' do
    let(:iplc_response_item) { double('IplcWrapper') }

    before do
      expect(SubmitIplcListenerJob::IplcWrapper).to receive(:new).with(request, 'iplc-uuid').and_return(
        iplc_response_item
      )
    end

    context 'when the item request in BorrowDirect throws an error' do
      before do
        expect(iplc_response_item).to receive(:success?).and_raise('The API Error')
      end

      it 'sends the request off to Symphony and notifies Honeybadger' do
        expect(Honeybadger).to receive(:notify).with(
          'IPLC Request failed for 1 with The API Error. Submitted to Symphony instead.'
        )
        expect(SubmitSymphonyRequestJob).to receive(:perform_now).with(request.id, {})

        subject.perform(request.id, 'iplc-uuid')
      end
    end

    context 'when the item is requestable and the request succeeds' do
      before do
        expect(iplc_response_item).to receive_messages(
          success?: true,
          as_json: { 'mockResponse' => ['Successful Response'], 'RequestNumber' => '1' }
        )

        allow(described_class).to receive(:perform_later)
      end

      it 'persists the BorrowDirect response' do
        subject.perform(request.id, 'iplc-uuid')

        expect(request.reload.borrow_direct_response_data).to eq(
          'mockResponse' => ['Successful Response'], 'RequestNumber' => '1'
        )
      end

      it 'sets the via_borrow_direct? flag to true' do
        subject.perform(request.id, 'iplc-uuid')

        expect(request.reload).to be_via_borrow_direct
      end

      it 'sends the approval status email' do
        expect(RequestStatusMailer).to receive(
          :request_status_for_holdrecall
        )

        subject.perform(request.id, 'iplc-uuid')
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
            .to_return(body: '{"total":0,"records":[]}')
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
