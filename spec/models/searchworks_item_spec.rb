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
  describe '#json', allow_apis: true do
    let(:json) { subject.send(:json) }
    it 'should return json as the body of the response object', allow_apis: true do
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
        'format' => %w(Format1 Format2),
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
    describe 'for a connection failure', allow_apis: true do
      before do
        allow(subject).to receive_messages(url: Settings.searchworks_api.gsub('searchworks', 'searchwroks'))
      end
      it 'should return an NullResponse when there is a connection error' do
        expect(subject.send(:response)).to be_a NullResponse
      end
      it 'should return blank json' do
        expect(subject.send(:json)).to eq({})
      end
      it 'should handle title, format, and holdings correctly' do
        expect(subject.title).to eq('')
        expect(subject.holdings).to eq([])
        expect(subject.format).to eq([])
      end
    end
    describe 'for a standard response' do
      before do
        allow(subject).to receive_messages(json: standard_json)
      end
      it 'should have a title string' do
        expect(subject.title).to eq('The title of the object')
      end
      it 'should have a format array' do
        expect(subject.format).to eq %w(Format1 Format2)
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
          expect(subject.all.first.request_status).to be_a SearchworksItem::RequestedHoldings::RequestStatus
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

    describe '#library_instructions' do
      let(:item) { build(:green_stacks_searchworks_item) }
      describe 'when not present' do
        it 'is nil' do
          expect(subject.library_instructions).to be_nil
        end
      end

      describe 'when present in the SearchWorks API response' do
        let(:item) { build(:library_instructions_searchworks_item) }
        it 'returns the library instructions from the API response' do
          expect(subject.library_instructions[:heading]).to eq 'Instruction Heading'
          expect(subject.library_instructions[:text]).to eq 'This is the library instruction'
        end
      end
    end

    describe 'barcoded holdings' do
      let(:item) { build(:green_stacks_multi_holdings_searchworks_item) }
      it 'should only return holdings that have the properly formatted barcode' do
        expect(subject.all.length).to eq 3
        expect(subject.barcoded_holdings.length).to eq 2
      end
    end

    describe 'mhld' do
      describe 'when not present' do
        let(:item) { build(:green_stacks_searchworks_item) }
        it 'returns an empty array' do
          expect(subject.mhld).to eq []
        end
      end
    end

    describe 'by_barcode' do
      let(:item) { build(:green_stacks_multi_holdings_searchworks_item) }
      it 'should return the items given an array of barcodes' do
        by_barcodes = subject.where(barcodes: %w(3610512345678 3610587654321))
        expect(by_barcodes).to be_a Array
        expect(by_barcodes.length).to eq 2
        expect(by_barcodes.first.barcode).to eq '3610512345678'
        expect(by_barcodes.last.barcode).to eq '3610587654321'
      end
      it 'should return the item given a single barcode' do
        by_barcodes = subject.where(barcodes: '12345679')
        expect(by_barcodes).to be_a Array
        expect(by_barcodes.length).to eq 1
        expect(by_barcodes.first.barcode).to eq '12345679'
      end
      it 'should return an empty array if the given barcode does not exist' do
        expect(subject.where(barcodes: 'not-a-barcode')).to eq([])
      end
    end

    describe SearchworksItem::RequestedHoldings::RequestStatus do
      let(:request) { create(:request) }
      let(:barcode) { '3610512345' }
      describe 'initialization' do
        it 'sets the request status data if not present' do
          expect(request.request_status_data).to be_nil
          described_class.new(request, barcode)
          expect(request.request_status_data).to be_a(Hash)
          expect(request.request_status_data[barcode]).to eq(
            'approved' => false,
            'approver' => nil,
            'approval_time' => nil
          )
        end
      end

      describe '#status_object' do
        let(:subject) { described_class.new(request, barcode) }
        it 'fetches the status object from the request_status_data hash' do
          expect(subject.status_object).to eq(
            'approved' => false,
            'approver' => nil,
            'approval_time' => nil
          )
        end

        it 'is updated when the item is approved' do
          expect(request).to receive(:save!)
          subject.approve!('jstanford')
          expect(subject.status_object['approved']).to be true
          expect(subject.status_object['approver']).to eq 'jstanford'
          expect(subject.status_object['approval_time']).not_to be_nil
        end
      end

      describe '#as_json' do
        let(:status) { described_class.new(request, barcode) }
        let(:json) { status.as_json }
        before { status.approve!('jstanford') }
        it 'returns the identifier' do
          expect(json[:id]).to eq barcode
        end

        it 'returns the approved status' do
          expect(json[:approved]).to be true
        end

        it 'returns the approver' do
          expect(json[:approver]).to eq 'jstanford'
        end

        it 'returns the formatted approval time' do
          expect(json[:approval_time]).to eq(
            I18n.l(Time.zone.parse(status.approval_time), format: :short)
          )
        end
      end

      describe 'accessors' do
        let(:subject) { described_class.new(request, barcode) }
        it 'aliases approved? to the status object' do
          expect(subject.approved?).to eq subject.status_object['approved']
        end

        it 'aliases approver to the status object' do
          expect(subject.approver).to eq subject.status_object['approver']
        end

        it 'aliases approval_time to the status object' do
          expect(subject.approval_time).to eq subject.status_object['approval_time']
        end
      end
    end
  end
end
