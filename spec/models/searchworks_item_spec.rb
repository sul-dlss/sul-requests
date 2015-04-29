require 'rails_helper'

describe SearchworksItem do
  let(:subject) { SearchworksItem.new('123') }

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
end
