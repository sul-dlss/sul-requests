# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PatronRequest do
  subject(:request) { described_class.new(instance_hrid: 'a12345', **attr) }

  let(:attr) { {} }
  let(:bib_data) { instance_double(Folio::Instance, title: 'Title') }

  before do
    allow(Folio::Instance).to receive(:fetch).with(request.instance_hrid).and_return(bib_data)
  end

  describe '#bib_data' do
    let(:bib_data) { instance_double(Folio::Instance) }

    it 'fetches the bib data from FOLIO' do
      request.instance_hrid = 'in00000063826'
      allow(Folio::Instance).to receive(:fetch).with('in00000063826').and_return(bib_data)

      expect(request.bib_data).to eq(bib_data)
    end

    it 'fetches the bib data from FOLIO, converting catkeys to FOLIO HRIDs as needed' do
      request.instance_hrid = '1234'
      allow(Folio::Instance).to receive(:fetch).with('a1234').and_return(bib_data)

      expect(request.bib_data).to eq(bib_data)
    end
  end

  describe '#scan?' do
    let(:attr) { { request_type: 'scan' } }

    it { is_expected.to be_scan }
  end

  describe '#aeon_page?' do
    let(:attr) { { instance_hrid: 'a12345', origin_location_code: 'SAL3-PAGE-AS' } }
    let(:bib_data) { build(:sal3_as_holding) }

    it 'is true if the holding location has an aeon site' do
      expect(request.aeon_page?).to be true
    end
  end

  describe '#aeon_site' do
    let(:attr) { { instance_hrid: 'a12345', origin_location_code: 'SAL3-PAGE-AS' } }
    let(:bib_data) { build(:sal3_as_holding) }

    it 'returns the aeon site for the holding location' do
      expect(request.aeon_site).to eq 'ARS'
    end
  end

  describe '#item_title' do
    it 'returns the title of the bib data' do
      expect(request.item_title).to eq('Title')
    end
  end

  describe '#selected_items' do
    let(:attr) { { instance_hrid: 'a123456', origin_location_code: 'SAL3-STACKS' } }
    let(:bib_data) { build(:scannable_holdings) }

    it 'returns the items with matching barcodes' do
      request.assign_attributes(barcodes: ['12345678'])
      expect(request.selected_items).to contain_exactly(have_attributes(callnumber: 'ABC 123'))
    end

    it 'returns items with matching item ids' do
      request.assign_attributes(barcodes: ['2'])
      expect(request.selected_items).to contain_exactly(have_attributes(callnumber: 'ABC 321'))
    end
  end

  describe '#barcode=' do
    it 'sets the barcodes attribute' do
      request.barcode = '1234567890'

      expect(request.barcodes).to eq(['1234567890'])
    end
  end

  describe '#pickup_service_point' do
    let(:bib_data) { build(:sal3_holdings) }

    context 'after the user has selected a service point' do
      let(:attr) { { service_point_code: 'GREEN-LOAN' } }

      it 'returns the selected service point' do
        expect(request.pickup_service_point).to have_attributes(name: 'Green Library')
      end
    end

    context 'with an item that must be picked up at a particular service point' do
      let(:bib_data) { build(:single_mediated_holding) }
      let(:attr) { { origin_location_code: 'ART-LOCKED-LARGE' } }

      it 'returns the service point' do
        expect(request.pickup_service_point).to have_attributes(name: 'Art & Architecture Library (Bowes)')
      end
    end

    context 'with a law item' do
      let(:attr) { { instance_hrid: 'a123', origin_location_code: 'LAW-STACKS1' } }
      let(:bib_data) { build(:single_law_holding) }

      it 'returns the law service point by default' do
        expect(request.pickup_service_point).to have_attributes(name: 'Law Library (Crown)')
      end
    end

    it 'returns the default service point' do
      expect(request.pickup_service_point).to have_attributes(name: 'Green Library')
    end
  end
end
