# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmitFolioScanRequestJob do
  let(:patron) do
    build(:patron)
  end
  let(:bib_data) { build(:single_holding) }
  let(:stub_client) { instance_double(FolioClient).as_null_object }
  let(:pseudopatron) do
    instance_double(Folio::Patron, id: 'GRE-SCANDELIVER-UUID')
  end

  before do
    stub_bib_data_json(bib_data)
    allow(FolioClient).to receive(:new).and_return(stub_client)
    allow(stub_client).to receive(:create_circulation_request).and_return({})

    allow(stub_client).to receive(:find_patron_by_barcode_or_university_id).with('GRE-SCANDELIVER').and_return(pseudopatron)
  end

  context 'when the request is a scan for material in e.g. Green' do
    let(:request) do
      PatronRequest.create(request_type: 'scan', instance_hrid: 'a1234', patron:, barcodes: ['12345678'],
                           origin_location_code: 'GRE-STACKS', scan_title: 'Test Scan')
    end

    let(:bib_data) { build(:green_holdings) }

    it 'pages items in FOLIO' do
      described_class.perform_now(request, bib_data.items[0].id)

      expect(stub_client).to have_received(:create_circulation_request).with(
        have_attributes(request_type: 'Page',
                        requester_id: 'GRE-SCANDELIVER-UUID',
                        pickup_service_point_id: 'a5dbb3dc-84f8-4eb3-8bfe-c61f74a9e92d')
      )
    end
  end
end
