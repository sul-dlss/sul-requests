# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LibraryLocation do
  describe '.library_name_by_code' do
    it 'returns the configured library\'s name' do
      expect(described_class.library_name_by_code('GREEN')).to eq 'Green Library'
      expect(described_class.library_name_by_code('SAL3')).to eq 'SAL3 (off-campus storage)'
    end

    it 'returns the label from Settings for a library like RWC without a FOLIO library code' do
      expect(described_class.library_name_by_code('RWC')).to eq 'Academy Hall (SRWC)'
    end

    it 'returns the code when there is no configured library' do
      expect(described_class.library_name_by_code('NOT-A-LIBRARY')).to eq 'NOT-A-LIBRARY'
    end
  end

  describe '#folio_location_code' do
    subject { library_location.folio_location_code }

    let(:library_location) { described_class.new(origin, origin_location) }

    context 'a symphony location' do
      let(:origin) { 'GREEN' }
      let(:origin_location) { 'STACKS' }

      it { is_expected.to eq 'GRE-STACKS' }
    end

    context 'a FOLIO location' do
      let(:origin) { 'BUSINESS' }
      let(:origin_location) { 'BUS-CRES' }

      it { is_expected.to eq 'BUS-CRES' }
    end
  end
end
