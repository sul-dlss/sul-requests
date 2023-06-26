# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::Patron do
  subject(:patron) do
    described_class.new(
      fields
    )
  end

  let(:fields) do
    {
      'username' => 'jcoyne85',
      'id' => '562a5cb0-e998-4ea2-80aa-34ac2b536238',
      'externalSystemId' => '09658748',
      'barcode' => '2555716958',
      'active' => true,
      'patronGroup' => '985acbb9-f7a7-4f44-9b34-458c02a78fbc',
      'departments' => [],
      'proxyFor' => [],
      'personal' =>
        { 'lastName' => 'Coyne',
          'firstName' => 'Justin',
          'middleName' => 'Michael',
          'email' => 'foliotesting@lists.stanford.edu',
          'phone' => '(612) 868-2411',
          'addresses' =>
          [{ 'countryId' => 'US',
             'addressLine1' => '4621 Ewing Ave S',
             'city' => 'Minneapolis',
             'region' => 'Minnesota',
             'postalCode' => '55410-1745',
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
      'customFields' => { 'affiliation' => 'staff', 'proximitychipid' => '0577826' }
    }
  end

  describe '#fee_borrower?' do
    it { is_expected.to be_fee_borrower }
  end
end
