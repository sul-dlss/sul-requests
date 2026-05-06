# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::Request do
  subject(:request) do
    described_class.new(record.with_indifferent_access)
  end

  let(:record) do
    {
      requestId: '572919e2-0817-49df-87bc-04c9775ae48d',
      'requestDate' => '2023-06-16T17:56:23.000+00:00',
      'item' =>
       { 'instanceId' => '4cd4ba91-394f-5efc-b867-75583a284583',
         'title' =>
         'A history of Persia : from the beginning of the nineteenth century to the year 1858
            / Robert Grant Watson ; with an introduction by Ali Ansari',
         'itemId' => '250cdadc-189b-5658-b2a9-c7d2fc31ab9b',
         'item' =>
         { 'circulationNotes' => [],
           'effectiveShelvingOrder' => 'DS 3298 W3 42023 11',
           'effectiveCallNumberComponents' => {
             'callNumber' => 'DS298 .W3 2023'
           },
           'effectiveLocation' => {
             'code' => 'SAL3-STACKS',
             'library' => { 'code' => 'SAL3' }
           } },
         'author' => 'Watson, Robert Grant',
         'instance' => { 'hrid' => 'a14439363' },
         'isbn' => nil },
      'status' => 'Open___Not_yet_filled',
      'expirationDate' => nil,
      'details' => {
        'holdShelfExpirationDate' => nil,
        'proxyUserId' => nil,
        'proxy' => nil,
        'requesterId' => 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1'
      },
      'pickupLocationId' => '4827ae1d-b8bf-4b90-9e09-d642557893ab',
      'pickupLocation' => { 'code' => 'EARTH-SCI' },
      'queueTotalLength' => 4,
      'queuePosition' => 3,
      'cancellationReasonId' => nil,
      'canceledByUserId' => nil,
      'cancellationAdditionalInformation' => nil,
      'canceledDate' => nil,
      'patronComments' => nil
    }
  end

  it_behaves_like 'folio_record'

  it 'responds to delegated methods' do
    expect(request).to respond_to(:library_name)
    expect(request).to respond_to(:library_code)
    expect(request).to respond_to(:from_ill?)
    expect(request).to respond_to(:effective_location)
    expect(request).to respond_to(:permanent_location)
  end

  describe '#key' do
    subject(:key) { request.key }

    it 'has a request key' do
      expect(key).to eq '572919e2-0817-49df-87bc-04c9775ae48d'
    end
  end

  describe '#patron_key' do
    subject(:patron_key) { request.patron_key }

    context 'when the request is not a proxy request' do
      it { expect(patron_key).to eq 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1' }
    end

    context 'when the request is a proxy request' do
      let(:record) do
        { 'details' =>
          { 'proxyUserId' => 'bdfa62a1-758c-4389-ae81-8ddb37860f9b',
            'proxy' => { 'firstName' => 'Piper', 'lastName' => 'Proxy', 'barcode' => 'Proxy1' } } }
      end

      it { expect(request.patron_key).to eq 'bdfa62a1-758c-4389-ae81-8ddb37860f9b' }
    end
  end

  describe '#proxy_request?' do
    context 'when the request is not a proxy request' do
      it { expect(request).not_to be_proxy_request }
    end

    context 'when the request is a proxy request' do
      let(:record) do
        { 'details' =>
          { 'proxyUserId' => 'bdfa62a1-758c-4389-ae81-8ddb37860f9b',
            'proxy' => { 'firstName' => 'Piper', 'lastName' => 'Proxy', 'barcode' => 'Proxy1' } } }
      end

      it { expect(request).to be_proxy_request }
    end
  end

  describe 'service_point_name' do
    let(:service_points) do
      build(:service_points)
    end

    before do
      allow(Folio::Types).to receive_messages(service_points: Folio::TypeStore.new(Folio::ServicePoint, service_points))
    end

    context 'when the code maps to a service point' do
      let(:record) do
        { 'pickupLocationId' => 'a5dbb3dc-84f8-4eb3-8bfe-c61f74a9e92d',
          'pickupLocation' => { 'code' => 'GREEN-LOAN' } }
      end

      it 'returns the service point name' do
        expect(request.service_point_name).to eq 'Green Library'
      end
    end

    context 'when the code does not map to a service point' do
      it 'returns the code as a fallback' do
        expect(request.service_point_name).to eq 'EARTH-SCI'
      end
    end
  end
end
