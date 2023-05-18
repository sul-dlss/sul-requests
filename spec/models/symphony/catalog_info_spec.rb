# frozen_string_literal: true

require 'rails_helper'

describe Symphony::CatalogInfo do
  subject(:info) { described_class.find('36105123456789') }

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

      it 'is blank' do
        expect(subject.current_location).to be_blank
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

      it 'is blank' do
        expect(subject.response).to be_blank
      end
    end

    context 'with a barcode that needs url escaping' do
      subject { described_class.find('abc 123') }

      before do
        stub_request(:get, %r{https://example.com/symws/catalog/item/barcode/abc%20123?.*})
          .to_return(response)
      end

      let(:response) { { body: '{ "success": true }' } }

      it 'escapes the barcode' do
        expect(subject.response).to eq({ 'success' => true })
      end
    end
  end

  describe '#cdlable?' do
    before do
      stub_request(:get, %r{https://example.com/symws/catalog/item/barcode/36105123456789?.*})
        .to_return(response)
    end

    let(:response) do
      {
        body: '{
          "resource": "/catalog/item",
          "key": "666:2:1",
          "fields": {
            "homeLocation": {
              "resource": "/policy/location",
              "key": "STACKS"
            }
          }
        }'
      }
    end

    it { is_expected.not_to be_cdlable }

    context 'with the right home location' do
      let(:response) do
        {
          body: '{
            "resource": "/catalog/item",
            "key": "666:2:1",
            "fields": {
              "homeLocation": {
                "resource": "/policy/location",
                "key": "CDL"
              }
            }
          }'
        }
      end

      it { is_expected.to be_cdlable }
    end
  end

  describe '#loan_period' do
    subject { info.loan_period }

    let(:response) do
      {
        body: %{{
          "resource": "/catalog/item",
          "key": "666:2:1",
          "fields": {
            "itemCategory3": {
              "key": "#{value}"
            }
          }
        }}
      }
    end

    before do
      stub_request(:get, %r{https://example.com/symws/catalog/item/barcode/36105123456789?.*})
        .to_return(response)
    end

    context 'with days' do
      let(:value) { 'CDL-7D' }

      it { is_expected.to eq 7.days }
    end

    context 'with hours' do
      let(:value) { 'CDL-4H' }

      it { is_expected.to eq 4.hours }
    end

    context 'with minutes' do
      let(:value) { 'CDL-16M' }

      it { is_expected.to eq 16.minutes }
    end

    context 'with garbage' do
      let(:value) { 'not a cdl value' }

      it { is_expected.to eq 2.hours }
    end
  end
end
