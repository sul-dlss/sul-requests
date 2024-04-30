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

  describe '#proxy_group_names' do
    let(:patron_one) { instance_double(Folio::Patron, id: 'proxy1', display_name: 'Proxy One') }
    let(:patron_two) { instance_double(Folio::Patron, id: 'proxy2', display_name: 'Proxy Two') }

    it 'retrieves the names of the proxy user ids correctly' do
      request.patron = instance_double(Folio::Patron, id: 'sponsor', display_name: 'Sponsor', email: nil)
      stub_client = FolioClient.new
      allow(FolioClient).to receive(:new).and_return(stub_client)
      allow(stub_client).to receive(:find_patron_by_id).with('proxy1').and_return(patron_one)
      allow(stub_client).to receive(:find_patron_by_id).with('proxy2').and_return(patron_two)
      allow(request.patron).to receive_messages(
        sponsor?: true,
        all_proxy_group_info: [{ 'proxyUserId' => 'proxy1', 'requestForSponsor' => 'Yes' },
                               { 'proxyUserId' => 'proxy2', 'requestForSponsor' => 'Yes' }]
      )
      expect(request.proxy_group_names.length).to eq 2
    end
  end
end
