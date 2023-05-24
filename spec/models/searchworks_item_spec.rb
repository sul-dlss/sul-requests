# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchworksItem do
  subject { described_class.new(request) }

  let(:request) { create(:request, item_id: '123') }

  describe 'api urls' do
    it 'returns the base uri from the settings.yml file' do
      expect(subject.send(:base_uri)).to eq(Settings.searchworks_api)
    end

    it 'returns a url for the searchworks api' do
      expect(subject.send(:url)).to eq("#{Settings.searchworks_api}/view/123/availability")
    end

    context 'by default' do
      it 'will request a live lookup by omitting any live parameter' do
        expect(subject.send(:url)).to eq("#{Settings.searchworks_api}/view/123/availability")
      end
    end

    context 'when the object is initialized with the live_lookup accessor set to false' do
      let(:subject) { described_class.new(request, false) }

      it 'the url will include a "live=false" flag' do
        expect(subject.send(:url)).to eq("#{Settings.searchworks_api}/view/123/availability?live=false")
      end
    end
  end

  describe '#json', allow_apis: true do
    let(:json) { subject.send(:json) }

    it 'returns json as the body of the response object', allow_apis: true do
      expect(json).to be_a Hash
      expect(json).to have_key 'title'
      expect(json).to have_key 'holdings'
    end

    it 'handles JSON Parser Errors by returning an empty hash' do
      response = double('response', body: 'not-json', success?: true)
      allow(subject).to receive_messages(response: response)
      expect(json).to eq({})
    end

    it 'returns an empty hash when the response is not a success' do
      response = double('response', success?: false)
      allow(subject).to receive_messages(response: response)
      expect(json).to eq({})
    end
  end

  describe '#response' do
    let(:standard_json) do
      {
        'title' => 'The title of the object',
        'format' => %w(Format1 Format2),
        'holdings' => [
          { 'code' => 'GREEN',
            'name' => 'Green Library',
            'locations' => [{
              'code' => 'STACKS',
              'name' => 'Stacks'
            }]
          }
        ]
      }
    end
    let(:empty_json) { {} }

    describe 'for a connection failure', allow_apis: true do
      before do
        stub_request(:get, %r{https://searchwroks.stanford.edu/.*}).to_timeout
        allow(subject).to receive_messages(url: Settings.searchworks_api.gsub('searchworks', 'searchwroks'))
      end

      it 'returns an NullResponse when there is a connection error' do
        expect(subject.send(:response)).to be_a NullResponse
      end

      it 'returns blank json' do
        expect(subject.send(:json)).to eq({})
      end

      it 'handles title, format, and holdings correctly' do
        expect(subject.title).to eq('')
        expect(subject.holdings).to eq([])
        expect(subject.format).to eq([])
      end
    end

    describe 'for a standard response' do
      before do
        allow(subject).to receive_messages(json: standard_json)
      end

      it 'has a title string' do
        expect(subject.title).to eq('The title of the object')
      end

      it 'has a format array' do
        expect(subject.format).to eq %w(Format1 Format2)
      end

      it 'has an array of nested OpenStruct objects describing the holdings' do
        expect(subject.holdings).to be_a Array
        expect(subject.holdings.length).to eq 1
        expect(subject.holdings.first).to be_a OpenStruct
        expect(subject.holdings.first.code).to eq 'GREEN'

        expect(subject.holdings.first.locations).to be_a Array
        expect(subject.holdings.first.locations.first).to be_a OpenStruct
        expect(subject.holdings.first.locations.first.code).to eq 'STACKS'
      end

      describe 'for an empty response' do
        before do
          allow(subject).to receive_messages(json: empty_json)
        end

        it 'has an empty title string' do
          expect(subject.title).to eq ''
        end

        it 'is an empty array' do
          expect(subject.holdings).to eq []
        end
      end
    end
  end

  describe SearchworksItem::RequestedHoldings do
    subject(:requested_holdings) { described_class.new(item.request, item.holdings) }

    describe 'in the searchworks item' do
      subject { build(:green_stacks_searchworks_item) }

      it 'return a SearchworksItem::RequestedHoldings object' do
        expect(subject.requested_holdings).to be_a described_class
      end
    end

    describe 'all' do
      describe 'items that exist' do
        let(:item) { build(:green_stacks_searchworks_item) }

        it 'are present for the requested location' do
          expect(subject.all).to be_a Array
          expect(subject.all.length).to eq 1
          expect(subject.all.first.barcode).to eq '12345678'
          expect(subject.all.first.callnumber).to eq 'ABC 123'
        end

        it 'adds the request_status object to the items' do
          expect(subject.all.first.request_status).to be_a ItemStatus
        end
      end

      describe 'items that do not exist' do
        let(:item) { build(:green_stacks_searchworks_item) }

        before do
          allow(item).to receive_messages(request: build(:request, origin: 'SAL3', origin_location: 'STACKS'))
        end

        it 'are not present for the requested location' do
          expect(subject.all).to eq([])
        end
      end
    end

    describe 'single_checked_out_item?' do
      subject(:requested_holdings) { described_class.new(instance_double(Request), instance_double(Array)) }

      describe 'when the holdings include a single checked out item' do
        before do
          allow(subject).to receive_messages(
            all: [
              double('holding', current_location: double('location', code: 'CHECKEDOUT'))
            ]
          )
        end

        it { is_expected.to be_single_checked_out_item }
      end

      describe 'when the holdings includes multiple items' do
        before do
          allow(subject).to receive_messages(
            all: [
              double('holding', current_location: double('location', code: 'CHECKEDOUT')),
              double('holding', current_location: nil)
            ]
          )
        end

        it { is_expected.not_to be_single_checked_out_item }
      end
    end

    describe '#by_barcode' do
      let(:item) { build(:green_stacks_multi_holdings_searchworks_item) }

      context 'when given an array of barcodes' do
        subject(:by_barcodes) { requested_holdings.where(barcodes: %w(3610512345678 3610587654321)) }

        it 'returns the items' do
          expect(by_barcodes).to be_a Array
          expect(by_barcodes.length).to eq 2
          expect(by_barcodes.first.barcode).to eq '3610512345678'
          expect(by_barcodes.last.barcode).to eq '3610587654321'
        end
      end

      context 'when given a single barcode' do
        subject(:by_barcodes) { requested_holdings.where(barcodes: ['12345679']) }

        it 'returns the items' do
          expect(by_barcodes).to be_a Array
          expect(by_barcodes.length).to eq 1
          expect(by_barcodes.first.barcode).to eq '12345679'
        end
      end

      context 'when the given barcode does not exist' do
        subject(:by_barcodes) { requested_holdings.where(barcodes: ['not-a-barcode']) }

        it { is_expected.to be_empty }
      end
    end
  end
end
