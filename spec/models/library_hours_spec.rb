# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LibraryHours do
  let(:library) { 'GREEN' }
  let(:subject) { described_class.new }

  describe '#business_days_for' do
    before do
      allow(LibraryHoursApi).to receive(:get).and_return(stub_library_hours_response)
    end

    let(:stub_library_hours_response) do
      LibraryHoursApi::Response.new(
        {
          'data' => {
            'attributes' => {
              'hours' => [
                { 'open' => true, 'opens_at' => '2025-01-29T09:00:00-06:00',
                  'closes_at' => '2025-01-29T17:00:00-06:00' },
                { 'open' => true, 'opens_at' => '2025-01-30T09:00:00-06:00',
                  'closes_at' => '2025-01-30T17:00:00-06:00' },
                { 'open' => true, 'opens_at' => '2025-02-03T09:00:00-06:00',
                  'closes_at' => '2025-02-03T17:00:00-06:00' },
                { 'open' => true, 'opens_at' => '2025-02-04T09:00:00-06:00',
                  'closes_at' => '2025-02-04T17:00:00-06:00' },
                { 'open' => true, 'opens_at' => '2025-02-05T09:00:00-06:00',
                  'closes_at' => '2025-02-05T17:00:00-06:00' }
              ]
            }
          }
        }
      )
    end

    it 'returns upcoming business days for a library' do
      schedule = subject.business_days_for(library, after: Time.zone.parse('2025-01-28'))

      expect(schedule).to eq([
                               Time.zone.parse('2025-01-29'),
                               Time.zone.parse('2025-01-30'),
                               Time.zone.parse('2025-02-03'),
                               Time.zone.parse('2025-02-04'),
                               Time.zone.parse('2025-02-05')
                             ])
    end

    it 'uses previously retrieved schedule data to complete a request to avoid redundant API calls' do
      subject.business_days_for(library, after: Time.zone.parse('2025-01-28'))
      subject.business_days_for(library, after: Time.zone.parse('2025-02-04'))

      expect(LibraryHoursApi).to have_received(:get).once
    end

    it 'requests updated data if the cached data is insufficient' do
      subject.business_days_for(library, after: Time.zone.parse('2025-01-28'))
      subject.business_days_for(library, after: Time.zone.parse('2025-03-04'))

      expect(LibraryHoursApi).to have_received(:get).with('green', 'library-circulation', from: Date.parse('2025-01-28'),
                                                                                          business_days: 7).once
      expect(LibraryHoursApi).to have_received(:get).with('green', 'library-circulation', from: Date.parse('2025-03-04'),
                                                                                          business_days: 7).once
    end
  end
end
