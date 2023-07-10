# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchworksItem do
  subject(:item) { described_class.new(request, '123') }

  before do
    allow(Request).to receive(:bib_model_class).and_return(described_class)
  end

  let(:request) { create(:request, item_id: '123') }
  let(:url) { "#{Settings.searchworks_api}/view/123/availability" }

  describe 'api urls' do
    it 'returns a url for the searchworks api' do
      allow(Faraday).to receive(:get).with(url).and_return(double('response',
                                                                  success?: true,
                                                                  body: '{}'))
      described_class.fetch(request, true)

      expect(Faraday).to have_received(:get)
    end

    context 'when the object is initialized with the live_lookup accessor set to false' do
      it 'the url will include a "live=false" flag' do
        allow(Faraday).to receive(:get).with("#{url}?live=false").and_return(double('response',
                                                                                    success?: true,
                                                                                    body: '{}'))
        described_class.fetch(request, false)

        expect(Faraday).to have_received(:get)
      end
    end

    it 'gracefully handles JSON Parser Errors' do
      allow(Faraday).to receive(:get).with(url).and_return(double('response',
                                                                  success?: true,
                                                                  body: 'not-json'))
      subject = described_class.fetch(request, true)

      expect(subject.title).to be_blank
    end

    it 'gracefully handles when the response is not a success' do
      allow(Faraday).to receive(:get).with(url).and_return(double('response',
                                                                  success?: false,
                                                                  body: 'not-json'))
      subject = described_class.fetch(request, true)
      expect(subject.title).to be_blank
    end

    describe 'for a connection failure', allow_apis: true do
      before do
        stub_request(:get, %r{https://searchworks.stanford.edu/.*}).to_timeout
      end

      it 'handles title, format, and holdings correctly' do
        subject = described_class.fetch(request, true)

        expect(subject.title).to eq('')
        expect(subject.holdings).to eq([])
        expect(subject.format).to eq([])
      end
    end
  end

  describe 'accessors' do
    subject(:item) { described_class.new(standard_json, '123') }

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

    context 'with a standard response' do
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
    end
  end
end
