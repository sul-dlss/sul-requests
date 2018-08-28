# frozen_string_literal: true

require 'rails_helper'

describe IlliadRequest do
  subject { described_class.new(user, scan) }

  let(:user) { create(:webauth_user) }
  let(:scan) { create(:scan_with_holdings_barcodes) }
  let(:client) { subject.connection_with_headers }

  describe 'illiad request json' do
    it 'includes the correct illiad routing info' do
      expect(subject.illiad_transaction_request).to include(ProcessType: 'Borrowing')
      expect(subject.illiad_transaction_request).to include(RequestType: 'Article')
      expect(subject.illiad_transaction_request).to include(SpecIns: 'Scan and Deliver Request')
      expect(subject.illiad_transaction_request).to include(Username: 'some-webauth-user')
    end
  end

  describe 'illiad transaction request and response' do
    context 'valid response' do
      let(:response) do
        resp_body =
          '{
            "TransactionNumber": 125,
            "Username": "jdoe",
            "RequestType": "Article",
            "PhotoJournalTitle" : "Journal of Interlibrary Loan,Document Delivery & Electronic Reserve",
            "PhotoJournalInclusivePages": "165-183",
            "PhotoArticleAuthor" : "Williams, Joseph; Woolwine, David",
            "PhotoArticleTitle" : "Interlibrary Loan in the United States",
            "ISSN": "1072-303X",
            "ILLNumber": "123456789",
            "CallNumber": "ABC123",
            "Location": "SAL3",
            "ProcessType": "Borrowing",
            "ItemNumber": "123456789",
            "CreationDate": "2016-10-01T10:25:37.19",
           }'
        double(success?: true, body: resp_body)
      end

      before do
        expect_any_instance_of(Faraday::Connection).to receive(:post).and_return(response)
      end

      it 'has a response body' do
        expect(subject.response.body).not_to be nil
      end
    end

    context 'invalid response' do
      let(:response) do
        resp_json = '{{"Message":"The request is invalid."}}'
        double(success?: true, body: resp_json)
      end

      before do
        expect_any_instance_of(Faraday::Connection).to receive(:post).and_return(response)
      end

      it 'has a error message' do
        expect(subject.response.body).to match(/The request is invalid./)
      end
    end

    context 'for an empty response' do
      let(:response) { double(success?: false, body: '') }

      before do
        expect_any_instance_of(Faraday::Connection).to receive(:post).and_return(response)
      end

      it 'is blank' do
        expect(subject.response.body).to eq ''
      end
    end

    context 'for a failed response' do
      before do
        allow_any_instance_of(Faraday::Connection).to receive(:post).and_raise(Faraday::ConnectionFailed, nil)
      end

      it 'is blank' do
        expect(subject.response).to be_an_instance_of NullResponse
      end
    end

    describe '#faraday_conn_w_req_headers' do
      it 'has required headers' do
        expect(client.headers).to include('ApiKey')
        expect(client.headers).to include('Accept' => 'application/json; version=1')
        expect(client.headers).to include('Content-type' => 'application/json')
      end
    end
  end
end
