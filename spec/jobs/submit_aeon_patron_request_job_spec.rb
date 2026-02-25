# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmitAeonPatronRequestJob do
  let(:patron) do
    build(:patron)
  end

  let(:request) do
    PatronRequest.create(request_type:, instance_hrid: 'a1234', patron:, barcodes: ['12345678'],
                         origin_location_code: 'SPEC-STACKS', data:)
  end
  let(:bib_data) { build(:special_collections_single_holding) }

  before do
    stub_bib_data_json(bib_data)
  end

  context 'when the request is a digitization request' do
    let(:request_type) { 'digitization' }
    let(:data) do
      {
        barcodes: ['12345678'], aeon_item: {
          'ABC 123': { pages: '23', publication: 'no', digitization_special: 'info' }
        }
      }
    end

    describe '#map_json' do
      it 'correctly maps the Aeon request object to an Aeon client payload' do
        mapped_json = described_class.new.map_json('aeon_username', request.aeon_requests.first)
        expect(JSON.parse(mapped_json)).to match(hash_including(
                                                   'callNumber' => 'ABC 123',
                                                   'documentType' => 'Monograph',
                                                   'forPublication' => false,
                                                   'itemAuthor' => 'John Q. Public',
                                                   'itemInfo1' => 'https://searchworks.stanford.edu/view/1234',
                                                   'itemInfo5' => '23',
                                                   'itemNumber' => '12345678',
                                                   'itemTitle' => 'Special Collections Item Title',
                                                   'location' => 'SPEC-STACKS',
                                                   'site' => 'SPECUA',
                                                   'shippingOption' => 'Electronic Delivery',
                                                   'specialRequest' => 'info',
                                                   'systemID' => 'sul-requests',
                                                   'username' => 'aeon_username',
                                                   'webRequestForm' => 'GenericRequestMonograph'
                                                 ))
      end
    end
  end
end
