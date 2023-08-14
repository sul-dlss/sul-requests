# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::PickupDestination do
  subject(:pickup_destination) do
    described_class.new(
      'GREEN-LOAN'
    )
  end

  let(:service_points_json) do
    <<~JSON
      [
        {
          "code": "GREEN-LOAN",
          "id": "a5dbb3dc-84f8-4eb3-8bfe-c61f74a9e92d",
          "discoveryDisplayName": "Green Library"
        }
      ]
    JSON
  end

  before do
    allow(Folio::Types.instance).to receive(:service_points).and_return(
      JSON.parse(service_points_json).map { |p| Folio::ServicePoint.from_dynamic(p) }.index_by(&:id)
    )
  end

  describe '#display_label' do
    it 'returns service point name' do
      expect(subject.display_label).to eq 'Green Library'
    end
  end

  describe '#paging_code' do
    let(:locations_json) do
      <<~JSON
        [
          {
            "id": "4573e824-9273-4f13-972f-cff7bf504217",
            "code": "GRE-STACKS",
            "discoveryDisplayName": "Stacks",
            "libraryId": "f6b5519e-88d9-413e-924d-9ed96255f72e",
            "primaryServicePoint": "a5dbb3dc-84f8-4eb3-8bfe-c61f74a9e92d"
          }
        ]
      JSON
    end

    let(:libraries_json) do
      <<~JSON
        [
          {
            "id": "f6b5519e-88d9-413e-924d-9ed96255f72e",
            "name": "Green Library",
            "code": "GREEN",
            "campusId": "c365047a-51f2-45ce-8601-e421ca3615c5"
          }
        ]
      JSON
    end

    before do
      allow(Folio::Types.instance).to receive(:libraries).and_return(
        JSON.parse(libraries_json).index_by { |p| p['id'] }
      )
      allow(Folio::Types.instance).to receive(:locations).and_return(
        JSON.parse(locations_json).index_by { |p| p['id'] }
      )
    end

    it 'returns library code for service point' do
      expect(subject.paging_code).to eq 'GREEN'
    end
  end
end
