require 'rails_helper'

describe LibraryHours do
  let(:library) { 'GREEN' }
  let(:subject) { described_class.new(library) }
  let(:today) { Time.zone.today }

  describe 'ConnectionFailed' do
    before do
      allow(Faraday.default_connection).to receive(:get).and_raise(Faraday::Error::ConnectionFailed, '')
    end
    it 'returns a NullResponse' do
      expect(subject.send(:response)).to be_a(NullResponse)
    end
  end

  describe '#library' do
    context 'Non-scan library' do
      it 'returns the library' do
        expect(subject.library).to eq 'GREEN'
      end
    end

    context 'scanning library' do
      let(:library) { 'SCAN' }
      it 'proxies SCAN to GREEN' do
        expect(subject.library).to eq 'GREEN'
      end
    end
  end

  describe 'bad JSON' do
    let(:response) { double('response') }
    before do
      allow(response).to receive_messages(success?: true)
      allow(response).to receive_messages(body: '<html />')
      allow(subject).to receive_messages(response: response)
    end
    it 'returns an empty hash' do
      expect(subject.send(:json)).to be {}
    end
  end

  describe 'stubbed JSON' do
    let(:json) { {} }
    before do
      allow(subject).to receive_messages(json: json)
    end

    describe 'business days' do
      let(:json) do
        {
          'data' => {
            'attributes' => {
              'hours' => [
                { 'opens_at' => "#{today - 2.days}", 'open' => false },
                { 'opens_at' => "#{today - 1.day}", 'open' => true },
                { 'opens_at' => "#{today}", 'open' => false },
                { 'opens_at' => "#{today + 1.day}", 'open' => false },
                { 'opens_at' => "#{today + 2.days}", 'open' => true }
              ]
            }
          }
        }
      end

      describe '#next_business_day' do
        it 'returns the next day that is open (starting from today) in the response' do
          expect(subject.next_business_day).to eq(today + 2.days)
        end

        it 'returns the next day that is open in the response given a particular date' do
          expect(
            subject.next_business_day(today - 2.days)
          ).to eq(today - 1.day)
        end
      end

      describe '#business_days' do
        it 'returns an array of only the open days in the response' do
          expect(subject.business_days).to be_a Array
          expect(subject.business_days.length).to eq 2
        end
      end
    end
  end

  describe '#api_url' do
    let(:api_url) { subject.send(:api_url) }
    it 'constructs a url containing the library slug' do
      expect(api_url).to match(%r{/libraries\/green/})
    end

    it 'constructs a url containing the location slug' do
      expect(api_url).to match(%r{/locations\/library-circulation/})
    end

    it 'constructs a url containing a date range of two months from today' do
      expect(api_url).to include("from=#{today}")
      expect(api_url).to include("to=#{today + 2.months}")
    end
  end
end
