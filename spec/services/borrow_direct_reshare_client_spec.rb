# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BorrowDirectReshareClient do
  subject(:client) { described_class.new(url:) }

  let(:url) { 'https://example.com' }
  let(:request_headers) do
    {
      'Accept' => 'application/json, text/plain',
      'Connection' => 'close',
      'Content-Type' => 'application/json',
      'Host' => 'example.com',
      'User-Agent' => 'ReShareApiClient',
      'X-Okapi-Token' => 'tokentokentoken'
    }
  end

  before do
    stub_request(:post, 'https://example.com/authn/login')
      .to_return(headers: { 'x-okapi-token': 'tokentokentoken' })
  end

  describe '#get' do
    before do
      stub_request(:get, 'https://example.com/blah')
        .with(headers: request_headers)
        .to_return(body: 'Hi!')
    end

    it 'sends a get request with okapi auth headers' do
      expect(client.get('/blah').body.to_s).to eq('Hi!')
    end

    context 'with a method' do
      before do
        stub_request(:post, 'https://example.com/blah')
          .with(headers: request_headers)
          .to_return(body: 'Hi!')
      end

      it 'overrides the request type' do
        expect(client.get('/blah', method: :post).body.to_s).to eq('Hi!')
      end
    end
  end

  describe '#get_json' do
    before do
      stub_request(:get, 'https://example.com/blah')
        .to_return(body:)
    end

    let(:body) { '{"hello": "world"}' }

    it 'parses json responses into ruby objects' do
      expect(client.get_json('/blah')).to eq('hello' => 'world')
    end

    describe 'when the response is empty' do
      let(:body) { '' }

      it 'returns nil' do
        expect(client.get_json('/blah')).to be_nil
      end
    end

    describe 'when the response status is not okay' do
      before do
        stub_request(:get, 'https://example.com/blah')
          .to_return(status: 403)
      end

      it 'raises an error' do
        expect { client.get_json('/blah') }.to raise_error(BorrowDirectReshareClient::BorrowDirectError)
      end
    end
  end

  describe '#requests' do
    before do
      stub_request(:get, 'https://example.com/rs/patronrequests?filters=isRequester=true&' \
                         'match=patronIdentifier&perPage=100&sort=dateCreated%3Bdesc&term=12345678')
        .with(headers: request_headers)
        .to_return(body:)
    end

    let(:body) do
      '[{"id": "00000000"}]'
    end

    it 'returns a list of requests' do
      expect(client.requests('12345678')).to eq([{ 'id' => '00000000' }])
    end
  end
end
