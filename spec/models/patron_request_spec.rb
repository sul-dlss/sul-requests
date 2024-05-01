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

    it 'returns all the items with matching barcodes' do
      request.assign_attributes(barcodes: ['87654321', '12345678'])

      expect(request.selected_items).to contain_exactly(
        have_attributes(callnumber: 'ABC 321'),
        have_attributes(callnumber: 'ABC 123')
      )
    end

    it 'returns items with matching item ids' do
      request.assign_attributes(barcodes: ['2'])
      expect(request.selected_items).to contain_exactly(have_attributes(callnumber: 'ABC 321'))
    end

    context 'for a scan' do
      it 'returns the first item' do
        request.assign_attributes(request_type: 'scan', barcodes: ['12345678', '87654321'])

        expect(request.selected_items).to contain_exactly(have_attributes(callnumber: 'ABC 123'))
      end
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

  describe '#pickup_destinations' do
    let(:bib_data) { build(:sal3_holdings) }

    it 'includes all the default pickup service points from FOLIO' do
      expect(request.pickup_destinations).to include('GREEN-LOAN', 'SCIENCE', 'ART', 'MUSIC')
    end

    context 'with an item from an origin library that is not a default pickup service point' do
      let(:bib_data) { build(:mmstacks_holding) }
      let(:attr) { { instance_hrid: 'a123', origin_location_code: 'MEDIA-CAGE' } }

      it 'also includes the service point from the origin library' do
        expect(request.pickup_destinations).to include('MEDIA-CENTER')
      end
    end

    context 'with a location-restricted page' do
      let(:bib_data) { build(:page_lp_holdings) }
      let(:attr) { { instance_hrid: 'a1234', origin_location_code: 'SAL3-PAGE-LP' } }

      it 'only includes the allowed service points' do
        expect(request.pickup_destinations).to contain_exactly('MEDIA-CENTER', 'MUSIC')
      end
    end
  end

  describe '#mediateable?' do
    let(:bib_data) { build(:single_mediated_holding) }
    let(:attr) { { instance_hrid: 'a1234', origin_location_code: 'ART-LOCKED-LARGE' } }

    it { is_expected.to be_mediateable }
  end

  describe '#requires_needed_date?' do
    context 'with a mediated item' do
      let(:bib_data) { build(:single_mediated_holding) }
      let(:attr) { { instance_hrid: 'a1234', origin_location_code: 'ART-LOCKED-LARGE' } }

      it { is_expected.to be_requires_needed_date }
    end

    context 'with a PAGE-MP mediated item' do
      let(:bib_data) { build(:page_mp_holdings) }
      let(:attr) { { instance_hrid: 'a1234', origin_location_code: 'SAL3-PAGE-MP' } }

      it { is_expected.not_to be_requires_needed_date }
    end

    context 'with a recall' do
      let(:bib_data) { build(:checkedout_holdings) }
      let(:attr) { { instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS', barcode: '87654321' } }

      it { is_expected.to be_requires_needed_date }
    end

    context 'with an ordinary item' do
      let(:bib_data) { build(:checkedout_holdings) }
      let(:attr) { { instance_hrid: 'a1234', origin_location_code: 'SAL3-STACKS', barcode: '12345678' } }

      it { is_expected.not_to be_requires_needed_date }
    end
  end

  describe '#destination_library_code' do
    let(:bib_data) { build(:sal3_holdings) }
    let(:attr) { { origin_location_code: 'SAL3-STACKS' } }

    it 'is the library code for the service desk' do
      request.service_point_code = 'GREEN-LOAN'
      expect(request.destination_library_code).to eq 'GREEN'

      request.service_point_code = 'MUSIC'
      expect(request.destination_library_code).to eq 'MUSIC'
    end
  end
end
