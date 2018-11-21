# frozen_string_literal: true

require 'rails_helper'

describe LibraryLocation do
  let(:request) { Request.new }
  it 'should include the mediateable mixin' do
    expect(request.library_location).to be_a Mediateable
  end
  it 'should include the scannable mixin' do
    expect(request.library_location).to be_a Scannable
  end
  it 'should include the hold recallable mixin' do
    expect(request.library_location).to be_a HoldRecallable
  end
  describe '#pageable?' do
    it 'should be true if the LibraryLocation is not mediatable or hold recallable' do
      request.origin = 'GREEN'
      request.origin_location = 'STACKS'
      expect(request.library_location).to be_pageable
    end

    it 'is false when the LibraryLocation is hold recallable' do
      request.requested_barcode = '3610512345678'
      expect(request.library_location).to_not be_pageable
    end

    it 'should be false if the LibraryLocation is mediatable' do
      request.origin = 'SPEC-COLL'
      request.origin_location = 'STACKS'
      expect(request.library_location).to_not be_pageable
    end
  end
  describe '#pickup_libraries' do
    it 'should return all pickup libraries when the given library and location are not configured' do
      request.origin = 'GREEN'
      request.origin_location = 'STACKS'
      expect(LibraryLocation.new(request).pickup_libraries.keys).to eq SULRequests::Application.config.pickup_libraries
    end
    it 'should return pickup libraries specific to a library if configured' do
      request.origin = 'ARS'
      request.origin_location = 'STACKS'
      expect(LibraryLocation.new(request).pickup_libraries).to eq('ARS' => 'Archive of Recorded Sound')
    end
    it 'should return pickup libraries specific to a location if configured' do
      request.origin = 'SAL3'
      request.origin_location = 'PAGE-MU'
      expect(LibraryLocation.new(request).pickup_libraries).to eq('MUSIC' => 'Music Library')
    end

    it 'should return pickup libraries that include itself (when configured)' do
      request.origin = 'MEDIA-MTXT'
      request.origin_location = 'MM-STACKS'
      expect(LibraryLocation.new(request).pickup_libraries.keys).to include('MEDIA-MTXT')
    end
  end
  describe '#library_name_by_code' do
    it 'should return the configured library\'s name' do
      expect(LibraryLocation.library_name_by_code('GREEN')).to eq 'Green Library'
      expect(LibraryLocation.library_name_by_code('SAL3')).to eq 'SAL3 (off-campus storage)'
    end

    it 'returns the library name for pickups specific codes if present' do
      expect(LibraryLocation.library_name_by_code('PAGE-MP')).to eq 'Earth Sciences Library (Branner)'
    end

    it 'should return nil when there is no configured library' do
      expect(LibraryLocation.library_name_by_code('NOT-A-LIBRARY')).to be_nil
    end
  end

  describe '#mhld' do
    let(:request) { create(:page_with_holdings_summary) }
    let(:subject) { LibraryLocation.new(request) }
    it 'should return the requested locations MHLD data if present' do
      expect(subject.mhld).to be_present
      expect(subject.mhld.library_has).to eq 'This is the library has holdings summary'
    end
  end
end
