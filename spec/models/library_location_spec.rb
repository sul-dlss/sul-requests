# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LibraryLocation do
  describe '.library_name_by_code' do
    it 'returns the configured library\'s name' do
      expect(described_class.library_name_by_code('GREEN')).to eq 'Green Library'
      expect(described_class.library_name_by_code('SAL3')).to eq 'SAL3 (off-campus storage)'
    end

    it 'returns nil when there is no configured library' do
      expect(described_class.library_name_by_code('NOT-A-LIBRARY')).to be_nil
    end
  end

  describe '#folio_location_code' do
    subject { library_location.folio_location_code }

    let(:library_location) { described_class.new(origin, origin_location) }
    let(:origin) { 'GREEN' }
    let(:origin_location) { 'STACKS' }

    it { is_expected.to eq 'GRE-STACKS' }
  end
end
