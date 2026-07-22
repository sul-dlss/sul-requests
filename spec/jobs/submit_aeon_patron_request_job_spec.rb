# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmitAeonPatronRequestJob do
  let(:patron) do
    build(:patron)
  end

  let(:request) do
    PatronRequest.create!(request_type:, instance_hrid: 'a1234', patron:,
                          origin_location_code: 'SPEC-STACKS', data:, patron_request_items_attributes:, user: build(:sso_user))
  end
  let(:data) { {} }
  let(:folio_instance) { build(:special_collections_single_holding) }
  let(:stub_aeon_client) { instance_double(AeonClient, find_user: stub_aeon_user, create_request: Aeon::Request.new, update_request_route: nil) }
  let(:stub_aeon_user) { instance_double(Aeon::User, username: 'aeon_user') }

  before do
    stub_folio_instance_json(folio_instance)
    allow(AeonClient).to receive(:new).and_return(stub_aeon_client)
  end

  context 'when the request is a digitization request' do
    let(:request_type) { 'scan' }
    let(:patron_request_items_attributes) do
      [
        { barcode: '12345678', request_type: 'scan', requested_pages: '23', for_publication: 'false', additional_information: 'info' }
      ]
    end

    describe '#perform_now' do
      it 'correctly maps the Aeon request object to an Aeon client payload' do
        described_class.perform_now(request)

        expect(stub_aeon_client).to have_received(:create_request).with(an_object_having_attributes(
                                                                          call_number: 'ABC 123',
                                                                          document_type: 'Book',
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
                                                                          username: 'aeon_user',
                                                                          web_request_form: 'single'
                                                                        ))
      end
    end
  end

  describe '#create_aeon_requests' do
    let(:attr) do
      {
        instance_hrid: 'a1234', origin_location_code: 'SPEC-STACKS',
        request_type:,
        data:
      }
    end

    context 'with single item digitization request' do
      let(:folio_instance) { build(:special_collections_single_holding) }
      let(:request_type) { 'scan' }
      let(:patron_request_items_attributes) do
        [
          { barcode: '12345678', request_type: 'scan', requested_pages: '23', for_publication: 'false', additional_information: 'info' }
        ]
      end

      it 'creates an aeon request with digitization fields' do
        described_class.perform_now(request)

        expect(stub_aeon_client).to have_received(:create_request).with(an_object_having_attributes(
                                                                          special_request: 'info',
                                                                          item_info5: '23',
                                                                          for_publication: false,
                                                                          shipping_option: 'Electronic Delivery'
                                                                        ))
      end
    end

    context 'with single item reading room request' do
      let(:folio_instance) { build(:special_collections_single_holding) }
      let(:request_type) { 'pickup' }
      let(:patron_request_items_attributes) do
        [
          { barcode: '12345678', request_type: 'pickup', appointment_id: '99', additional_information: 'Some info' }
        ]
      end

      it 'creates an aeon request with reading room fields' do
        described_class.perform_now(request)

        expect(stub_aeon_client).to have_received(:create_request).with(an_object_having_attributes(
                                                                          special_request: 'Some info',
                                                                          shipping_option: nil
                                                                        ))
      end
    end

    context 'with a pickup request whose aeon_item still carries digitization fields' do
      let(:folio_instance) { build(:special_collections_single_holding) }
      let(:request_type) { 'pickup' }
      let(:patron_request_items_attributes) do
        [
          { barcode: '12345678', request_type: 'pickup', appointment_id: '99', requested_pages: '23', for_publication: 'false',
            additional_information: 'info' }
        ]
      end

      it 'does not pass digitization fields to Aeon' do
        described_class.perform_now(request)

        expect(stub_aeon_client).to have_received(:create_request).with(an_object_having_attributes(
                                                                          appointment_id: 99,
                                                                          item_info5: nil,
                                                                          for_publication: nil
                                                                        ))
      end
    end

    context 'with a scan request whose aeon_item still carries an appointment_id' do
      let(:folio_instance) { build(:special_collections_single_holding) }
      let(:request_type) { 'scan' }
      let(:patron_request_items_attributes) do
        [
          { barcode: '12345678', request_type: 'scan', requested_pages: '23', for_publication: 'false', additional_information: 'info',
            appointment_id: '99' }
        ]
      end

      it 'does not pass the appointment_id to Aeon' do
        described_class.perform_now(request)

        expect(stub_aeon_client).to have_received(:create_request).with(an_object_having_attributes(
                                                                          appointment_id: nil,
                                                                          item_info5: '23'
                                                                        ))
      end
    end

    context 'with an activity request' do
      let(:folio_instance) { build(:special_collections_single_holding) }
      let(:request_type) { 'activity' }
      let(:patron_request_items_attributes) do
        [
          { barcode: '12345678', additional_information: 'info' }
        ]
      end

      let(:data) { { request_type: 'activity', activity_ids: %w[3 4] } }

      it 'creates one Aeon request per activity_id' do
        described_class.perform_now(request)

        expect(stub_aeon_client).to have_received(:create_request).with(an_object_having_attributes(activity_id: '3'))
        expect(stub_aeon_client).to have_received(:create_request).with(an_object_having_attributes(activity_id: '4'))
      end
    end

    context 'when some items in a multi-item request fail' do
      let(:request_type) { 'scan' }
      let(:folio_instance) do
        items = %w[111 222 333].map do |barcode|
          build(:item, barcode: barcode, base_callnumber: "CALL #{barcode}",
                       status: 'Available', effective_location: build(:spec_coll_location))
        end
        build(:special_collections_holdings, items: items)
      end
      let(:patron_request_items_attributes) do
        [
          { barcode: '111', request_type: 'scan', requested_pages: '1', for_publication: 'false', additional_information: 'first' },
          { barcode: '222', request_type: 'scan', requested_pages: '2', for_publication: 'false', additional_information: 'second' },
          { barcode: '333', request_type: 'scan', requested_pages: '3', for_publication: 'false', additional_information: 'third' }
        ]
      end
      let(:response) do
        Faraday.new do |b|
          b.adapter(:test) { |s| s.post('/Requests/create') { [500, {}, '{"err":"error message"}'] } }
        end.post('/Requests/create', '{"username":"aeon_user"}')
      end

      before do
        allow(stub_aeon_client).to receive(:create_request).and_invoke(
          ->(_) { raise AeonClient::ApiError, response },
          ->(_) { Aeon::Request.new },
          ->(_) { raise AeonClient::ApiError, response }
        )
        allow(Honeybadger).to receive(:notify)
      end

      it 'logs every item, notifies Honeybadger per failure, and raises SubmissionFailure' do
        expect { described_class.perform_now(request) }
          .to raise_error(SubmitAeonPatronRequestJob::SubmissionFailure, /Failed to create 2 Aeon request/)

        expect(Honeybadger).to have_received(:notify).twice.with(an_instance_of(AeonClient::ApiError))

        rows = request.aeon_api_responses
        expect(rows.count).to eq(3)
        error_rows = rows.select { |r| r.response_data['status'] == 500 }
        expect(error_rows.size).to eq(2)

        expect(error_rows.first.response_data).to include(
          'status' => 500,
          'method' => 'POST',
          'request_body' => '{"username":"aeon_user"}',
          'response_body' => '{"err":"error message"}'
        )
        expect(error_rows.first.request_data).to include('username' => 'aeon_user')
      end
    end

    context 'with multi item digitization request' do
      let(:folio_instance) { build(:special_collections_holdings) }
      let(:request_type) { 'scan' }
      let(:patron_request_items_attributes) do
        [
          { barcode: '12345678', request_type: 'scan', requested_pages: '23', for_publication: 'false', additional_information: 'info' },
          { barcode: '87654321', request_type: 'scan', requested_pages: '32', for_publication: 'true', additional_information: 'more info' }
        ]
      end

      it 'creates multiple aeon requests with digitization fields' do
        described_class.perform_now(request)

        expect(stub_aeon_client).to have_received(:create_request).with(an_object_having_attributes(
                                                                          item_info5: '23', special_request: 'info'
                                                                        ))

        expect(stub_aeon_client).to have_received(:create_request).with(an_object_having_attributes(
                                                                          for_publication: true,
                                                                          item_info5: '32',
                                                                          special_request: 'more info'
                                                                        ))
      end
    end
  end
end
