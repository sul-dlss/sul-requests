require 'rails_helper'

describe LibraryLocation do
  let(:request) { Request.new }
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
  end
end
