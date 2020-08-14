# frozen_string_literal: true

require 'rails_helper'

describe SymphonyCurrLocRequest do
  subject { described_class.new(barcode: '36105123456789') }

  before do
    stub_request(:post, 'https://example.com/symws/user/staff/login')
      .with(body: Settings.symws.login_params.to_h)
      .to_return(body: { sessionToken: 'tokentokentoken' }.to_json)
  end

  describe '#current_location' do
    before do
      stub_request(:get, %r{https://example.com/symws/catalog/item/barcode/36105123456789?.*})
        .to_return(response)
    end

    let(:response) { { body: '' } }

    context 'valid response' do
      let(:response) do
        {
          body: '{
            "resource": "/catalog/item",
            "key": "666:2:1",
            "fields": {
              "currentLocation": {
                "resource": "/policy/location",
                "key": "SOUTH-MEZZ"
              }
            }
          }'
        }
      end

      it 'has a value' do
        expect(subject.current_location).to eq 'SOUTH-MEZZ'
      end
    end

    context 'json without info' do
      let(:response) do
        {
          body: '{
            "resource": "/catalog/item",
            "key": "666:2:1",
            "fields": {
            }
          }'
        }
      end

      it 'returns empty string' do
        expect(subject.current_location).to eq ''
      end
    end

    context 'for an error response' do
      let(:response) { { status: [500, 'Internal Server Error'] } }

      it 'is blank' do
        expect(subject.current_location).to be_blank
      end
    end

    context 'for a failed response' do
      before do
        stub_request(:get, %r{https://example.com/symws/catalog/item/barcode/36105123456789?.*})
          .to_timeout
      end

      it 'is blank' do
        expect(subject.current_location).to be_blank
      end
    end

    context 'invalid JSON returned' do
      let(:response) { { body: 'symphony returned an error instead of JSON' } }

      it 'returns empty hash' do
        expect(subject.send(:json)).to eq({})
      end
    end

    context 'with a barcode that needs url escaping' do
      subject { described_class.new(barcode: 'abc 123') }

      before do
        stub_request(:get, %r{https://example.com/symws/catalog/item/barcode/abc%20123?.*})
          .to_return(response)
      end

      let(:response) { { body: '{ "success": true }' } }

      it 'escapes the barcode' do
        expect(subject.send(:json)).to eq({ 'success' => true })
      end
    end
  end
end
