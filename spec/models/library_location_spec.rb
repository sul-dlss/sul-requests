# frozen_string_literal: true

require 'rails_helper'

describe LibraryLocation do
  let(:request) { Request.new }

  describe '#pickup_libraries' do
    it 'returns all pickup libraries when the given library and location are not configured' do
      request.origin = 'GREEN'
      request.origin_location = 'STACKS'
      expect(described_class.new(request).pickup_libraries.keys).to eq SULRequests::Application.config.pickup_libraries
    end

    it 'returns pickup libraries specific to a library if configured' do
      request.origin = 'ARS'
      request.origin_location = 'STACKS'
      expect(described_class.new(request).pickup_libraries).to eq('ARS' => 'Archive of Recorded Sound')
    end

    it 'returns pickup libraries specific to a location if configured' do
      request.origin = 'SAL3'
      request.origin_location = 'PAGE-MU'
      expect(described_class.new(request).pickup_libraries).to eq('MUSIC' => 'Music Library')
    end

    it 'returns pickup libraries that include itself (when configured)' do
      request.origin = 'MEDIA-MTXT'
      request.origin_location = 'MM-STACKS'
      expect(described_class.new(request).pickup_libraries.keys).to include('MEDIA-MTXT')
    end

    it 'returns pickup libraries for library/location specific combinations' do
      request.origin = 'EDUCATION'
      request.origin_location = 'LOCKED-STK'
      expect(described_class.new(request).pickup_libraries).to eq('SPEC-COLL' => 'Special Collections')
    end

    it 'returns all pickup libraries for library that have a location specific config defined' do
      request.origin = 'EDUCATION'
      request.origin_location = 'STACKS'
      expect(described_class.new(request).pickup_libraries.keys).to eq SULRequests::Application.config.pickup_libraries
    end
  end

  describe '#library_name_by_code' do
    it 'returns the configured library\'s name' do
      expect(described_class.library_name_by_code('GREEN')).to eq 'Green Library'
      expect(described_class.library_name_by_code('SAL3')).to eq 'SAL3 (off-campus storage)'
    end

    it 'returns the library name for pickups specific codes if present' do
      expect(described_class.library_name_by_code('PAGE-MP')).to eq 'Earth Sciences Library (Branner)'
    end

    it 'returns nil when there is no configured library' do
      expect(described_class.library_name_by_code('NOT-A-LIBRARY')).to be_nil
    end
  end
end
