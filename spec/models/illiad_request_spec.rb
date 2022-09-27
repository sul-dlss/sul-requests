# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IlliadRequest do
  subject { described_class.new(scan) }

  let(:user) { create(:sso_user) }
  let(:scan) { create(:scan_with_holdings_barcodes, user: user) }

  describe 'illiad request json' do
    it 'includes the correct illiad routing info' do
      expect(subject.illiad_transaction_request).to include('"Username":"some-sso-user"')
      expect(subject.illiad_transaction_request).to include('"ProcessType":"Borrowing"')
      expect(subject.illiad_transaction_request).to include('"RequestType":"Article"')
      expect(subject.illiad_transaction_request).to include('"SpecIns":"Scan and Deliver Request"')
    end
  end

  describe 'illiad transaction request and response' do
    context 'valid response' do
      it 'fires off a request to the illiad api' do
        expect_any_instance_of(Faraday::Connection).to receive(:post)
        subject.request!
      end
    end

    describe '#faraday_conn_w_req_headers' do
      it 'has required headers' do
        faraday_conn = subject.send(:faraday_conn_w_req_headers)
        expect(faraday_conn.headers).to include('ApiKey')
        expect(faraday_conn.headers).to include('Accept' => 'application/json; version=1')
        expect(faraday_conn.headers).to include('Content-type' => 'application/json')
      end
    end
  end
end
