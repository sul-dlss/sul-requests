# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PickupLibrariesHelper do
  describe '#pickup_libraries_array' do
    let(:libraries) do
      %w[ABC XYZ]
    end

    let(:service_points_json) do
      <<~JSON
        [
          {
            "id": "ABC",
            "code": "ABC",
            "discoveryDisplayName": "Library 2"
          },
          {
            "id": "XYZ",
            "code": "XYZ",
            "discoveryDisplayName": "Library 1"
          }
        ]
      JSON
    end

    before do
      allow(Settings).to receive(:libraries).and_return(
        {
          'ABC' => double(Config::Options, label: 'Library 2'),
          'XYZ' => double(Config::Options, label: 'Library 1')
        }
      )

      allow(Folio::Types.instance).to receive(:service_points).and_return(
        JSON.parse(service_points_json).map { |p| Folio::ServicePoint.from_dynamic(p) }.index_by(&:id)
      )
    end

    it 'sorts the libraries by the name of the library (and not the code)' do
      pickup_libraries = helper.send(:pickup_destinations_array, libraries)

      expect(pickup_libraries).to eq([['Library 1', 'XYZ'], ['Library 2', 'ABC']])
    end
  end
end
