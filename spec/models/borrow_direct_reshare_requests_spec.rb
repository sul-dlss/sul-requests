# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BorrowDirectReshareRequests do
  subject(:bd_requests) { described_class.new(patron_university_id) }

  let(:patron_university_id) { '12345678' }

  let(:in_process_request) do
    { 'id' => '11111111',
      'state' => { 'code' => 'REQ_SHIPPED' },
      'patronIdentifier' => '12345678',
      'title' => 'A title',
      'dateCreated' => '2022-12-05' }
  end

  let(:completed_request) do
    { 'state' => { 'code' => 'REQ_REQUEST_COMPLETE' }, 'patronIdentifier' => '12345678' }
  end

  let(:request_client) do
    instance_double(BorrowDirectReshareClient)
  end

  before { allow(BorrowDirectReshareClient).to receive(:new).and_return(request_client) }

  context 'when successful' do
    before do
      allow(request_client).to receive(:requests).with(patron_university_id)
                                                 .and_return([in_process_request, completed_request])
    end

    it 'only return requests with active statuses' do
      expect(bd_requests.requests.length).to be(1)
    end
  end

  context 'when the Patron university_id does not match the patron_id in the response' do
    let(:request_with_wrong_patron) do
      { 'state' => { 'code' => 'REQ_SHIPPED' }, 'patronIdentifier' => '7777777' }
    end

    before do
      allow(request_client).to receive(:requests).with(patron_university_id)
                                                 .and_return([request_with_wrong_patron])
    end

    it 'only return requests for the current patron' do
      expect(bd_requests.requests.length).to be(0)
    end
  end

  context 'when the patron does not have a university_id' do
    let(:patron_university_id) { nil }

    it 'returns an empty array' do
      expect(bd_requests.requests).to eq([])
    end
  end

  describe 'BorrowDirectReshareRequests::ReshareRequest' do
    let(:request) do
      BorrowDirectReshareRequests::ReshareRequest.new(in_process_request)
    end

    context 'when in an active state' do
      it { expect(request).to be_active }
    end

    context 'when not in an active state' do
      let(:request) do
        BorrowDirectReshareRequests::ReshareRequest.new(completed_request)
      end

      it { expect(request).not_to be_active }
    end

    it 'returns the dateCreated as the date_submitted' do
      expect(request.date_submitted.to_s).to eq '2022-12-05'
    end

    context 'when dateCreated value is missing' do
      let(:request) do
        BorrowDirectReshareRequests::ReshareRequest.new('id' => '00000000')
      end

      it 'date_submitted is nil' do
        expect(request.date_submitted).to be_nil
      end
    end

    context 'when dateCreated value is not parseable as a date' do
      let(:request) do
        BorrowDirectReshareRequests::ReshareRequest.new('dateCreated' => 'some string')
      end

      it 'date_submitted is nil' do
        expect(request.date_submitted).to be_nil
      end
    end

    it 'always returns nil for expiration_date' do
      expect(request.expiration_date).to be_nil
    end

    it 'always returns nil for fill_by_date' do
      expect(request.fill_by_date).to be_nil
    end

    it 'returns the request id as the key' do
      expect(request.key).to eq '11111111'
    end

    it 'returns the patronIdentifier as the patron_id' do
      expect(request.patron_id).to eq '12345678'
    end

    it 'always returns nil for service_point' do
      expect(request.service_point).to be_nil
    end

    it { expect(request).not_to be_ready_for_pickup }

    it 'returns the state code as the request_status' do
      expect(request.request_status).to eq 'REQ_SHIPPED'
    end

    describe '#sort_key' do
      context 'when title' do
        it { expect(request.sort_key(:title)).to eq 'A title' }
      end

      context 'when date' do
        it { expect(request.sort_key(:date)).to eq "#{Folio::Request::END_OF_DAYS.strftime('%FT%T')}---A title" }
      end

      context 'when any other sort value' do
        it { expect(request.sort_key(:something_else)).to eq '' }
      end
    end

    it 'returns the title' do
      expect(request.title).to eq 'A title'
    end
  end
end
