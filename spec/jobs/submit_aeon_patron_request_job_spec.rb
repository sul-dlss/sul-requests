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
  let(:stub_aeon_client) { instance_double(AeonClient, create_request: {}) }

  before do
    stub_bib_data_json(bib_data)
    allow(AeonClient).to receive(:new).and_return(stub_aeon_client)
  end

  context 'when the request is a digitization request' do
    let(:request_type) { 'digitization' }
    let(:data) do
      {
        barcodes: ['12345678'], aeon_item: {
          'ABC 123': { requested_pages: '23', for_publication: 'no', additional_information: 'info' }
        }
      }
    end

    describe '#perform_now' do
      it 'correctly maps the Aeon request object to an Aeon client payload' do
        described_class.perform_now(request, username: 'aeon_username')

        expect(stub_aeon_client).to have_received(:create_request).with(an_object_having_attributes(
                                                                          call_number: 'ABC 123',
                                                                          document_type: 'Monograph',
                                                                          for_publication: false,
                                                                          item_author: 'John Q. Public',
                                                                          item_info1: 'https://searchworks.stanford.edu/view/1234',
                                                                          item_info5: '23',
                                                                          item_number: '12345678',
                                                                          item_title: 'Special Collections Item Title',
                                                                          location: 'SPEC-STACKS',
                                                                          site: 'SPECUA',
                                                                          shipping_option: 'Electronic Delivery',
                                                                          special_request: 'info',
                                                                          username: 'aeon_username',
                                                                          web_request_form: 'GenericRequestMonograph'
                                                                        ))
      end
    end
  end
end
