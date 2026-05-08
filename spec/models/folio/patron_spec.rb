# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::Patron do
  subject(:patron) do
    described_class.new(
      fields.deep_stringify_keys, extended_user_info: extended_user_info&.deep_stringify_keys
    )
  end

  let(:fields) { {} }
  let(:extended_user_info) { nil }

  context 'when the patron is a fee borrower' do
    let(:patron_group_id) { '985acbb9-f7a7-4f44-9b34-458c02a78fbc' } # fee borrower
    let(:active) { true }
    let(:fields) do
      {
        'username' => 'jcoyne85',
        'id' => '562a5cb0-e998-4ea2-80aa-34ac2b536238',
        'externalSystemId' => '09658748',
        'barcode' => '5555555555',
        'active' => active,
        'patronGroup' => patron_group_id,
        'departments' => [],
        'proxyFor' => [],
        'personal' =>
        { 'lastName' => 'Germain',
          'firstName' => 'Jean',
          'middleName' => 'Louise',
          'email' => 'foliotesting@example.com',
          'phone' => '(555) 555-5555',
          'addresses' =>
          [{ 'countryId' => 'US',
             'addressLine1' => '600 Lowry Ave S',
             'city' => 'Nulltown',
             'region' => 'Indiana',
             'postalCode' => '55555',
             'addressTypeId' => '93d3d88d-499b-45d0-9bc7-ac73c3a19880',
             'primaryAddress' => true }],
          'preferredContactTypeId' => '002' },
        'enrollmentDate' => '2022-09-01T00:00:00.000+00:00',
        'createdDate' => '2023-05-20T00:13:20.324+00:00',
        'updatedDate' => '2023-05-20T00:13:20.324+00:00',
        'metadata' =>
          { 'createdDate' => '2023-02-10T02:14:56.209+00:00',
            'createdByUserId' => '3e2ed889-52f2-45ce-8a30-8767266f07d2',
            'updatedDate' => '2023-05-20T00:13:20.249+00:00',
            'updatedByUserId' => '9c77fffb-9d40-422c-8742-4c0f79957888' },
        'customFields' => { 'affiliation' => 'staff', 'proximitychipid' => '0000001' }
      }
    end

    describe '#ilb_eligible?' do
      it { is_expected.not_to be_ilb_eligible }

      context 'in an eligible patron group' do
        let(:fields) { super().merge('patronGroup' => 'bdc2b6d4-5ceb-4a12-ab46-249b9a68473e') }

        it { is_expected.to be_ilb_eligible }
      end

      context 'without a username' do
        let(:fields) { super().merge('patronGroup' => 'bdc2b6d4-5ceb-4a12-ab46-249b9a68473e').except('username') }

        it { is_expected.not_to be_ilb_eligible }
      end
    end

    describe '#make_request_as_patron?' do
      let(:folio_client) { instance_double(FolioClient, extended_user_info:) }
      let(:extended_user_info) do
        { 'blocks' => [
          {
            patronBlockConditionId: 'ac13a725-b25f-48fa-84a6-4af021d13afe',
            blockBorrowing: false,
            blockRenewals: false,
            blockRequests: true,
            message: 'Patron has reached maximum allowed outstanding fee/fine balance for his/her patron group'
          }
        ] }
      end

      before do
        allow(described_class).to receive(:folio_client).and_return(folio_client)
      end

      it { is_expected.to be_make_request_as_patron }

      context 'the patron is not active' do
        let(:active) { false }

        it { is_expected.not_to be_make_request_as_patron }
      end
    end

    context 'when the patron is an undergrad' do
      let(:patron_group_id) { 'bdc2b6d4-5ceb-4a12-ab46-249b9a68473e' } # undergrad

      describe '#ilb_eligible?' do
        it { is_expected.to be_ilb_eligible }
      end
    end
  end

  describe '#proxies' do
    let(:fields) do
      {
        id: 'sponsor',
        personal: { firstName: 'Sponsor' }
      }
    end

    let(:extended_user_info) do
      {
        proxiesOf: [
          {
            proxyUserId: 'proxy1',
            requestForSponsor: 'Yes',
            status: 'Active',
            proxyUser: {
              id: 'proxy1'
            }
          },
          {
            proxyUserId: 'proxy2',
            requestForSponsor: 'Yes',
            status: 'Active',
            proxyUser: {
              id: 'proxy2'
            }
          },
          {
            proxyUserId: 'proxy-expired',
            requestForSponsor: 'Yes',
            expirationDate: '2023-05-20T00:13:20.324+00:00',
            status: 'Active'
          },
          {
            proxyUserId: 'proxy-inactive',
            requestForSponsor: 'Yes',
            expirationDate: '2051-05-20T00:13:20.324+00:00',
            status: 'Inactive'
          }
        ]
      }
    end

    it 'retrieves the names of the proxy user ids correctly' do
      expect(patron.proxies.length).to eq 2
    end
  end

  describe '#sponsors' do
    let(:fields) do
      {
        id: 'proxy',
        personal: { firstName: 'Proxy' }
      }
    end

    let(:extended_user_info) do
      {
        proxiesFor: [
          {
            userId: 'sponsor1',
            requestForSponsor: 'Yes',
            status: 'Active',
            user: {
              id: 'sponsor1'
            }
          },
          {
            userId: 'sponsor2',
            requestForSponsor: 'Yes',
            status: 'Active',
            user: {
              id: 'sponsor2'
            }
          },
          {
            userId: 'sponsor-expired',
            requestForSponsor: 'Yes',
            expirationDate: '2023-05-20T00:13:20.324+00:00',
            status: 'Active'
          },
          {
            userId: 'sponsor-inactive',
            requestForSponsor: 'Yes',
            expirationDate: '2051-05-20T00:13:20.324+00:00',
            status: 'Inactive'
          }
        ]
      }
    end

    it 'retrieves the names of the sponsor user ids correctly' do
      expect(patron.sponsors.length).to eq 2
    end
  end
end
