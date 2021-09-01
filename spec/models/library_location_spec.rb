# frozen_string_literal: true

require 'rails_helper'

describe LibraryLocation do
  let(:request) { Request.new }

  describe '#pickup_libraries' do
    it 'returns all pickup libraries when the given library and location are not configured' do
      expect(described_class.new('GREEN', 'STACKS').pickup_libraries.keys).to eq SULRequests::Application.config.pickup_libraries
    end

    it 'returns pickup libraries specific to a library if configured' do
      expect(described_class.new('ARS', 'STACKS').pickup_libraries).to eq('ARS' => 'Archive of Recorded Sound')
    end

    it 'returns pickup libraries specific to a location if configured' do
      expect(described_class.new('SAL3', 'PAGE-MU').pickup_libraries).to eq('MUSIC' => 'Music Library')
    end

    it 'returns pickup libraries that include itself (when configured)' do
      expect(described_class.new('MEDIA-MTXT', 'MM-STACKS').pickup_libraries.keys).to include('MEDIA-MTXT')
    end

    it 'returns pickup libraries for library/location specific combinations' do
      expect(described_class.new('EDUCATION', 'LOCKED-STK').pickup_libraries).to eq('SPEC-COLL' => 'Special Collections')
    end

    it 'returns all pickup libraries for library that have a location specific config defined' do
      expect(described_class.new('EDUCATION', 'STACKS').pickup_libraries.keys).to eq SULRequests::Application.config.pickup_libraries
    end
  end

  describe '#library_name_by_code' do
    it 'returns the configured library\'s name' do
      expect(described_class.library_name_by_code('GREEN')).to eq 'Green Library'
      expect(described_class.library_name_by_code('SAL3')).to eq 'SAL3 (off-campus storage)'
    end

    it 'returns nil when there is no configured library' do
      expect(described_class.library_name_by_code('NOT-A-LIBRARY')).to be_nil
    end
  end
end
