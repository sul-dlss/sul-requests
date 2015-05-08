require 'rails_helper'

describe SearchworksItem do
  let(:request) { create(:request, item_id: '123') }
  let(:subject) { SearchworksItem.new(request) }

  describe 'api urls' do
    it 'should return the base uri from the settings.yml file' do
      expect(subject.send(:base_uri)).to eq(Settings.searchworks_api)
    end
    it 'should return a url for the searchworks api' do
      expect(subject.send(:url)).to eq("#{Settings.searchworks_api}/view/123/availability")
    end
  end
  describe '#json' do
    let(:json) { subject.send(:json) }
    it 'should return json as the body of the response object' do
      expect(json).to be_a Hash
      expect(json).to have_key 'title'
      expect(json).to have_key 'holdings'
    end
    it 'should handle JSON Parser Errors by returning an empty hash' do
      response = double('response', body: 'not-json', success?: true)
      allow(subject).to receive_messages(response: response)
      expect(json).to eq({})
    end
    it 'should return an empty hash when the response is not a success' do
      response = double('response', success?: false)
      allow(subject).to receive_messages(response: response)
      expect(json).to eq({})
    end
  end
  describe '#response' do
    let(:standard_json) do
      {
        'title' => 'The title of the object',
        'holdings' => [
          { 'code' => 'GREEN',
            'name' => 'Green Library',
            'locations' => [
              'code' => 'STACKS',
              'name' => 'Stacks'
            ]
          }
        ]
      }
    end
    let(:empty_json) { {} }
    describe 'for a connection failure' do
      before do
        allow(subject).to receive_messages(url: Settings.searchworks_api.gsub('searchworks', 'searchwroks'))
      end
      it 'should return an NullResponse when there is a connection error' do
        expect(subject.send(:response)).to be_a SearchworksItem::NullResponse
      end
      it 'should return blank json' do
        expect(subject.send(:json)).to eq({})
      end
      it 'should handle title and holdings correctly' do
        expect(subject.title).to eq('')
        expect(subject.holdings).to eq([])
      end
    end
    describe 'for a standard response' do
      before do
        allow(subject).to receive_messages(json: standard_json)
      end
      it 'should have a title string' do
        expect(subject.title).to eq('The title of the object')
      end
      it 'should have an array of nested OpenStruct objects describing the holdings' do
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
        it 'should have an empty title string' do
          expect(subject.title).to eq ''
        end
        it 'should be an empty array' do
          expect(subject.holdings).to eq []
        end
      end
    end
  end

  describe SearchworksItem::RequestedHoldings do
    describe 'in the searchworks item' do
      let(:subject) { build(:green_stacks_searchworks_item) }
      it 'return a SearchworksItem::RequestedHoldings object' do
        expect(subject.requested_holdings).to be_a SearchworksItem::RequestedHoldings
      end
    end
    let(:subject) { SearchworksItem::RequestedHoldings.new(item) }
    describe 'items' do
      describe 'items that exist' do
        let(:item) { build(:green_stacks_searchworks_item) }
        it 'are present for the requested location' do
          expect(subject.items).to be_a Array
          expect(subject.items.length).to eq 1
          expect(subject.items.first.barcode).to eq '12345678'
          expect(subject.items.first.callnumber).to eq 'ABC 123'
        end
      end

      describe 'items that do not exist' do
        let(:item) { build(:green_stacks_searchworks_item) }
        before do
          allow(item).to receive_messages(request: build(:request, origin: 'SAL3', origin_location: 'STACKS'))
        end
        it 'are not present for the requested location' do
          expect(subject.items).to eq([])
        end
      end
    end

    describe 'by_barcode' do
      let(:item) { build(:green_stacks_multi_holdings_searchworks_item) }
      it 'should return the items given an array of barcodes' do
        by_barcodes = subject.by_barcodes(%w(12345678 87654321))
        expect(by_barcodes).to be_a Array
        expect(by_barcodes.length).to eq 2
        expect(by_barcodes.first.barcode).to eq '12345678'
        expect(by_barcodes.last.barcode).to eq '87654321'
      end
      it 'should return the item given a single barcode' do
        by_barcodes = subject.by_barcodes('12345679')
        expect(by_barcodes).to be_a Array
        expect(by_barcodes.length).to eq 1
        expect(by_barcodes.first.barcode).to eq '12345679'
      end
      it 'should return an empty array if the given barcode does not exist' do
        expect(subject.by_barcodes('not-a-barcode')).to eq([])
      end
    end
  end
end
