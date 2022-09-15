# frozen_string_literal: true

require 'rails_helper'

describe SubmitBorrowDirectRequestJob, type: :job do
  let(:user) { create(:library_id_user) }
  let(:request) { create(:hold_recall_with_holdings, user: user) }
  let(:sw_item) { double('SeachWorksItem', isbn: %w[12345 54321]) }

  before do
    Sidekiq.logger.level = Logger::UNKNOWN
    allow(Patron).to receive(:find_by).with(library_id: user.library_id).at_least(:once).and_return(
      double(exists?: true, email: nil)
    )
    allow(request).to receive(:searchworks_item).and_return(sw_item)
  end

  it 'notifies Honeybadger when the job is called with a request that does not exist (and returns true)' do
    expect_any_instance_of(Honeybadger).to receive(:notify).once.with(
      'Attempted to call BorrowDirect for Request with ID -1, but no such Request was found.'
    )

    expect(subject.perform(-1)).to be true
  end

  describe '#perform' do
    let(:borrow_direct_item) { double('BorrowDirectWrapper') }

    before do
      expect(SubmitBorrowDirectRequestJob::BorrowDirectWrapper).to receive(:new).with(request).and_return(
        borrow_direct_item
      )
    end

    context 'when the item is not requestable in BorrowDirect' do
      before { expect(borrow_direct_item).to receive(:requestable?).and_return(false) }

      it 'sends the request off to Symphony (without attempting to request it)' do
        expect(borrow_direct_item).not_to receive(:request_item)
        expect(SubmitSymphonyRequestJob).to receive(:perform_now).with(request.id, {})

        subject.perform(request.id)
      end
    end

    context 'when the item request in BorrowDirect does not succeed' do
      before do
        expect(borrow_direct_item).to receive_messages(
          requestable?: true,
          request_item: false
        )
      end

      it 'sends the request off to Symphony' do
        expect(SubmitSymphonyRequestJob).to receive(:perform_now).with(request.id, {})

        subject.perform(request.id)
      end
    end

    context 'when the item request in BorrowDirect throws an error' do
      before do
        expect(borrow_direct_item).to receive(:requestable?).and_raise(BorrowDirect::Error, 'The API Error')
      end

      it 'sends the request off to Symphony and notifies Honeybadger' do
        expect(Honeybadger).to receive(:notify).with(
          'BorrowDirect Request failed for 1 with The API Error. Submitted to Symphony instead.'
        )
        expect(SubmitSymphonyRequestJob).to receive(:perform_now).with(request.id, {})

        subject.perform(request.id)
      end
    end

    context 'when the item is requestable and the request succeeds' do
      let(:user) { create(:webauth_user) }

      before do
        expect(borrow_direct_item).to receive_messages(
          requestable?: true,
          request_item: { 'mockResponse' => ['Successful Response'], 'RequestNumber' => '1' }
        )
      end

      it 'persists the BorrowDirect response' do
        subject.perform(request.id)

        expect(request.reload.borrow_direct_response_data).to eq(
          'mockResponse' => ['Successful Response'], 'RequestNumber' => '1'
        )
      end

      it 'sets the via_borrow_direct? flag to true' do
        subject.perform(request.id)

        expect(request.reload).to be_via_borrow_direct
      end

      it 'sends the approval status email' do
        expect(RequestStatusMailer).to receive(
          :request_status_for_holdrecall
        ).at_least(:once).with(request).and_call_original

        subject.perform(request.id)
      end
    end
  end

  describe SubmitBorrowDirectRequestJob::BorrowDirectWrapper do
    subject(:borrow_direct_request) { described_class.new(request) }

    describe '#requestable?' do
      let(:bd_response) do
        { 'mockResponse' => ['Successful Response'], 'RequestNumber' => '1' }
      end

      let(:stub_find_client) { double('BorrowDirect::FindItem') }

      context 'when the SearchWorksItem does not have an ISBN' do
        before { expect(sw_item).to receive(:isbn).and_return(nil) }

        it do
          expect(subject).not_to be_requestable
        end
      end

      context 'when the SearchWorksItem has an ISBN but the item is not available in BorrowDirect' do
        before do
          expect(stub_find_client).to receive(:find).and_return(
            double('BorrowDirect::Response', requestable?: false)
          )
          expect(subject).to receive(:find_client).and_return(stub_find_client)
        end

        it do
          expect(subject).not_to be_requestable
        end
      end

      context 'when the SearchWorksItem has an ISBN and the item is available in BorrowDirect' do
        before do
          expect(stub_find_client).to receive(:find).and_return(
            double('BorrowDirect::Response', requestable?: true)
          )
          expect(subject).to receive(:find_client).and_return(stub_find_client)
        end

        it do
          expect(subject).to be_requestable
        end
      end
    end

    describe '#request_item' do
      let(:bd_response) do
        { 'mockResponse' => ['Successful Response'], 'RequestNumber' => '1' }
      end

      let(:stub_request_client) { double('BorrowDirect::RequestItem', request_item_request: bd_response) }

      before do
        expect(subject).to receive(:request_client).and_return(stub_request_client)
      end

      describe 'pickup library' do
        context 'when the API does not have any pickup libraries (e.g. a find was not requested)' do
          it 'we assume the library is correct and submit it' do
            request.destination = 'LATHROP'
            expect(stub_request_client).to receive(:request_item_request).with('Lathrop Library', Hash)

            expect(subject.request_item).to be_present
          end
        end

        context 'when the requested pickup library is not in the list returned by the API' do
          it 'we fallback to the default pickup library and notify Honeybadger' do
            expect(subject).to receive(:api_pickup_locations).at_least(:once).and_return(%w[Library1 Library2 Library3])

            request.destination = 'LATHROP'
            expect(stub_request_client).to receive(:request_item_request).with('Green Library', Hash)
            expect(Honeybadger).to receive(:notify).with(
              'Request id 1 attempted to submit a BorrowDirect request to be picked up at Lathrop Library '\
              'but the only pickup libraries are Library1, Library2, and Library3'
            )
            expect(subject.request_item).to be_present
          end
        end

        context 'when the requested pickup library is in the list' do
          it 'we send the requested library' do
            expect(subject).to receive(:api_pickup_locations).at_least(:once).and_return(
              ['Green Library', 'Music Library', 'Law Library (Crown)']
            )

            request.destination = 'MUSIC'
            expect(stub_request_client).to receive(:request_item_request).with('Music Library', Hash)

            expect(subject.request_item).to be_present
          end
        end
      end

      describe 'search criteria' do
        it 'is the first ISBN' do
          expect(stub_request_client).to receive(:request_item_request).with(String, isbn: '12345')

          expect(subject.request_item).to be_present
        end
      end

      context 'when an auth_id is set' do
        before { expect(subject).to receive(:auth_id).at_least(:once).and_return('abc123') }

        it 'is used with the request client in order to not have duplicate the authentication request' do
          expect(stub_request_client).to receive(:with_auth_id).with('abc123').and_return(stub_request_client)

          expect(subject.request_item).to be_present
        end
      end

      context 'when the BorrowDirect request is successful' do
        it 'is the BorrowDirect Response' do
          expect(subject.request_item).to eq bd_response
        end
      end

      context 'when the BorrowDirect request is unsuccessful' do
        let(:bd_response) do
          { 'mockResponse' => ['Not Successful Response'] }
        end

        it 'is false' do
          expect(subject.request_item).to be false
        end
      end
    end

    describe 'Finding items' do
      let(:stub_find_client) { double('BorrowDirect::FindItem') }

      before do
        expect(subject).to receive(:find_client).and_return(stub_find_client)
        expect(stub_find_client).to receive(:find).with(isbn: '12345').and_return(
          double('BorrowDirect::Response', auth_id: 'AuthID123', pickup_locations: %w[Library1 Library2])
        )
      end

      describe 'auth_id' do
        it 'is set if the find response has one' do
          expect(subject.auth_id).to be_nil
          subject.send(:finder)
          expect(subject.auth_id).to eq 'AuthID123'
        end
      end

      describe 'api_pickup_locations' do
        it 'is set if the find response has pickup_locations' do
          expect(subject.api_pickup_locations).to be_nil
          subject.send(:finder)
          expect(subject.api_pickup_locations).to eq %w[Library1 Library2]
        end
      end
    end

    describe 'clients' do
      it do
        expect(subject.send(:find_client)).to be_a BorrowDirect::FindItem
      end

      it do
        expect(subject.send(:request_client)).to be_a BorrowDirect::RequestItem
      end
    end
  end
end
