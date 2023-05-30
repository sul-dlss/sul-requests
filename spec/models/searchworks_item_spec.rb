# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchworksItem do
  before do
    allow(Request).to receive(:bib_model_class).and_return(described_class) 
  end

  subject(:item) { described_class.new(request) }

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
      allow(subject).to receive_messages(response:)
      expect(json).to eq({})
    end

    it 'returns an empty hash when the response is not a success' do
      response = double('response', success?: false)
      allow(subject).to receive_messages(response:)
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
              'name' => 'Stacks',
              'items' => []
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

    context 'with a standard response' do
      before do
        allow(item).to receive_messages(json: standard_json)
      end

      it 'has a title string' do
        expect(subject.title).to eq('The title of the object')
      end

      it 'has a format array' do
        expect(subject.format).to eq %w(Format1 Format2)
      end

      describe '#holdings' do
        subject(:holdings) { item.holdings }

        it 'has an array of Searchworks::Holding objects describing the holdings' do
          expect(holdings).to be_a Array
          expect(holdings.length).to eq 1
          expect(holdings.first).to be_a Searchworks::Holding
          expect(holdings.first.code).to eq 'GREEN'

          expect(holdings.first.locations).to be_a Array
          expect(holdings.first.locations.first).to be_a Searchworks::HoldingLocation
          expect(holdings.first.locations.first.code).to eq 'STACKS'
        end
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
end
