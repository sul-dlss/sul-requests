# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PickupLibrariesHelper do
  describe '#pickup_libraries_array' do
    let(:libraries) do
      %w[ABC XYZ]
    end

    before do
      allow(Settings).to receive(:libraries).and_return(
        {
          'ABC' => double(Config::Options, label: 'Library 2'),
          'XYZ' => double(Config::Options, label: 'Library 1')
        }
      )
    end

    it 'sorts the libraries by the name of the library (and not the code)' do
      pickup_libraries = helper.send(:pickup_libraries_array, libraries)

      expect(pickup_libraries).to eq([['Library 1', 'XYZ'], ['Library 2', 'ABC']])
    end
  end

  describe '#default_pickup_library' do
    it 'sets an origin specific default' do
      default = helper.send(:default_pickup_library, Request.new(origin: 'LAW', origin_location: 'STACKS'))

      expect(default).to eq 'LAW'
    end

    it 'sets an origin location specific default' do
      default = helper.send(:default_pickup_library, Request.new(origin: 'SAL3', origin_location: 'EAL-SETS'))

      expect(default).to eq 'EAST-ASIA'
    end

    it 'falls back to a default location' do
      default = helper.send(:default_pickup_library, Request.new(origin: 'ART', origin_location: 'STACKS'))

      expect(default).to eq 'GREEN'
    end
  end
end
