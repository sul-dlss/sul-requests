require 'rails_helper'
require 'faraday'

describe SymphonyCurrLocRequest do
  subject { SymphonyCurrLocRequest.new(barcode: '36105123456789') }

  describe '#current_location' do
    context 'valid response' do
      let(:response) do
        resp_body =
          '{
            "resource": "/catalog/item",
            "key": "666:2:1",
            "fields": {
              "currentLocation": {
                "resource": "/policy/location",
                "key": "SOUTH-MEZZ"
              }
            }
          }'
        double(success?: true, body: resp_body)
      end
      before do
        expect_any_instance_of(Faraday::Connection).to receive(:get).and_return(response)
      end
      it 'has a value' do
        expect(subject.current_location).to eq 'SOUTH-MEZZ'
      end
    end
    context 'json without info' do
      let(:response) do
        resp_body =
          '{
            "resource": "/catalog/item",
            "key": "666:2:1",
            "fields": {
            }
          }'
        double(success?: true, body: resp_body)
      end
      before do
        expect_any_instance_of(Faraday::Connection).to receive(:get).and_return(response)
      end
      it 'returns empty string' do
        expect(subject.current_location).to eq ''
      end
    end
    context 'for an error response' do
      let(:response) { double(success?: false, body: '') }
      before do
        expect_any_instance_of(Faraday::Connection).to receive(:get).and_return(response)
      end
      it 'is blank' do
        expect(subject.current_location).to be_blank
      end
    end
    context 'for a failed response' do
      before do
        expect_any_instance_of(Faraday::Connection).to receive(:get).and_raise(Faraday::Error::ConnectionFailed, '')
      end
      it 'is blank' do
        expect(subject.current_location).to be_blank
      end
    end
  end

  it 'BASE_URL is concatenation of web services url and current_loc_path' do
    expect(SymphonyCurrLocRequest::BASE_URL).to eq 'http://example.com/symws/v1/catalog/item/barcode/'
  end

  context '#json (private)' do
    context 'invalid JSON returned' do
      let(:response) { double(success?: true, body: 'symphony returned an error instead of JSON') }
      before do
        expect_any_instance_of(Faraday::Connection).to receive(:get).and_return(response)
      end
      it 'returns empty hash' do
        expect(subject.send(:json)).to eq({})
      end
    end
  end

  context '#faraday_conn_w_req_headers' do
    it 'has required headers' do
      faraday_conn = subject.send(:faraday_conn_w_req_headers)
      expect(faraday_conn.headers).to include('x-sirs-clientID' => 'DS_CLIENT')
      expect(faraday_conn.headers).to include('sd-originating-app-id' => 'requests')
      expect(faraday_conn.headers).to include('SD-Preferred-Role' => 'GUEST')
    end
  end
end
