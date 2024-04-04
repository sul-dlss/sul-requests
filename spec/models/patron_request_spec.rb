# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PatronRequest do
  subject(:request) { described_class.new(**attr) }

  let(:attr) { {} }

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

  describe '#item_title' do
    let(:attr) { { instance_hrid: 'a12345' } }
    let(:bib_data) { instance_double(Folio::Instance, title: 'Title') }

    before do
      allow(Folio::Instance).to receive(:fetch).with('a12345').and_return(bib_data)
    end

    it 'returns the title of the bib data' do
      expect(request.item_title).to eq('Title')
    end
  end

  describe '#barcode=' do
    it 'sets the barcodes attribute' do
      request.barcode = '1234567890'

      expect(request.barcodes).to eq(['1234567890'])
    end
  end
end
