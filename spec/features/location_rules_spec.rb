# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Location rules configuration' do
  let(:aeon_pageable_location) do
    Folio::Location.new(id: nil, code: 'ARS-RECORDINGS', name: 'ARS Recordings', details:
      {
        page_aeon_site: 'ARS'
      })
  end

  let(:mediated_pageable_location) do
    Folio::Location.new(id: nil, code: 'SAL3-PAGE-MP', name: 'SAL3 PAGE-MP', details:
      {
        page_mediation_group_key: 'PAGE-MP',
        page_service_points: ['EARTH-SCI']
      })
  end

  let(:pageable_location) do
    Folio::Location.new(id: nil, code: 'SAL3-PAGE-LP', name: 'SAL3 Page to LP', details:
      {
        page_service_points: ['MUSIC', 'MEDIA-CENTER']
      })
  end

  let(:scannable_location) do
    Folio::Location.new(id: nil, code: 'SAL-HY-PAGE-EA', name: 'SAL HY Page to East-Asia', details:
      {
        scan_material_types: ['book', 'periodical'],
        scan_service_point: 'EAST-ASIA',
        scan_pseudopatron_barcode: 'EAL-SCANREVIEW'
      })
  end

  let(:locations) do
    [
      aeon_pageable_location,
      mediated_pageable_location,
      pageable_location,
      scannable_location
    ]
  end

  let(:rules) { Folio::LocationRules.rules_by_request_type(locations.map(&:rules).flatten) }

  let(:request) { Request.new }

  before do
    allow(RequestAbilities).to receive(:rules).and_return(rules)
    allow(Settings).to receive(:default_pickup_library).and_return('GREEN')
  end

  context 'when the requested item is in an aeon pageable location' do
    before do
      allow(request).to receive(:library_location).and_return(LibraryLocation.new('ARS', 'ARS-RECORDINGS'))
    end

    it 'is aeon pageable' do
      expect(request).to be_aeon_pageable
    end

    it 'has the configured site for delivery from aeon' do
      expect(request.aeon_site).to eq 'ARS'
    end
  end

  context 'when the requested item is in a mediated pageable location' do
    before do
      allow(request).to receive(:location).and_return(mediated_pageable_location)
    end

    it 'is mediated pageable' do
      expect(request).to be_mediateable
    end

    it 'only allows the configured service point for pickup' do
      expect(request.pickup_libraries).to eq ['EARTH-SCI']
    end
  end

  context 'when the requested item is in a pageable location' do
    before do
      allow(request).to receive(:location).and_return(pageable_location)
    end

    it 'is pageable' do
      expect(request).to be_pageable
    end

    it 'only allows the configured service points for pickup' do
      expect(request.pickup_libraries).to eq ['MUSIC', 'MEDIA-CENTER']
    end
  end

  context 'when the requested item is in a scannable location' do
    before do
      allow(request).to receive(:location).and_return(scannable_location)
    end

    context 'when the requested item is of a scannable material type' do
      before do
        allow(request).to receive(:material_type).and_return('book')
      end

      it 'is scannable' do
        expect(request).to be_scannable
      end

      it 'has the configured service point for scanning' do
        expect(request.pickup_libraries).to eq ['EAST-ASIA']
      end

      it 'has the configured pseudopatron barcode for scanning'
    end

    context 'when the requested item is not of a scannable material type' do
      before do
        allow(request).to receive(:material_type).and_return('map')
      end

      it 'is not scannable' do
        expect(request).not_to be_scannable
      end
    end
  end

  context 'when there are no rules matching the item' do
    before do
      allow(request).to receive(:location).and_return(Folio::Location.new(id: nil, code: 'GRE-STACKS', name: 'Green Stacks'))
    end

    it 'is pageable' do
      expect(request).to be_pageable
    end

    it 'uses the fallback service point for paging' do
      expect(request).pickup_libraries.to eq ['GREEN']
    end

    it 'is not scannable' do
      expect(request).not_to be_scannable
    end
  end
end
