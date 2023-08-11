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

      allow(Folio::Types.service_points).to receive(:find_by).with(code: 'ABC').and_return(instance_double(Folio::ServicePoint,
                                                                                                           name: 'Library 2'))

      allow(Folio::Types.service_points).to receive(:find_by).with(code: 'XYZ').and_return(instance_double(Folio::ServicePoint,
                                                                                                           name: 'Library 1'))
    end

    it 'sorts the libraries by the name of the library (and not the code)' do
      pickup_libraries = helper.send(:pickup_destinations_array, libraries)

      expect(pickup_libraries).to eq([['Library 1', 'XYZ'], ['Library 2', 'ABC']])
    end
  end
end
