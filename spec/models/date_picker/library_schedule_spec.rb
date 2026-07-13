# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DatePicker::LibrarySchedule do
  subject(:schedule) { described_class.new(library: library) }

  let(:library) { instance_double(Folio::Library, hours_codes: hours_codes) }

  describe '#availability_url' do
    context 'when the library has hours codes' do
      let(:hours_codes) { { library_slug: 'ars', location_slug: 'archive-recorded-sound' } }

      it 'points at the closures proxy for that library/location' do
        expect(schedule.availability_url).to eq(
          '/library_hours/ars/location/archive-recorded-sound/closures'
        )
      end
    end

    context 'when the library has no hours codes' do
      let(:hours_codes) { nil }

      it 'returns nil' do
        expect(schedule.availability_url).to be_nil
      end
    end

    context 'when no library is given' do
      subject(:schedule) { described_class.new(library: nil) }

      let(:hours_codes) { nil }

      it 'returns nil' do
        expect(schedule.availability_url).to be_nil
      end
    end
  end

  describe '#min' do
    context 'with an override' do
      subject(:schedule) { described_class.new(library: library, min: '2026-08-01') }

      let(:hours_codes) { nil }

      it 'uses the override' do
        expect(schedule.min).to eq('2026-08-01')
      end
    end
  end
end
