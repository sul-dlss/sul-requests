# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::Item do
  describe '.from_hash' do
    subject { described_class.from_hash(data) }

    context 'from a record without a barcode or callnumber' do
      let(:data) do
        { 'id' => 'a9030d19-5bbe-4976-ba31-ef8840f4145d',
          'tags' => { 'tagList' => [] },
          'notes' => [],
          'status' => 'On order',
          'location' =>
           { 'location' =>
             { 'code' => 'SAL3-STACKS',
               'name' => 'Off-campus storage',
               'campusName' => 'Stanford Libraries',
               'libraryName' => 'Stanford Auxiliary Library 3',
               'institutionName' => 'Stanford University' },
             'permanentLocation' => {},
             'temporaryLocation' => {} },
          'formerIds' => [],
          'callNumber' => {},
          'yearCaption' => [],
          'materialType' => 'book',
          'electronicAccess' => [],
          'holdingsRecordId' => 'fef99dba-15f4-495c-b391-e501afdaed6d',
          'statisticalCodes' => [],
          'permanentLoanType' => 'Can circulate',
          'suppressFromDiscovery' => false }
      end

      it { is_expected.to be_instance_of described_class }
    end

    context 'from a full record' do
      let(:data) do
        { 'id' => '195053fb-3c8e-5c54-854d-8806ec65fe52',
          'notes' => [],
          'status' => 'Available',
          'barcode' => '36105124065330',
          'location' =>
           { 'location' =>
             { 'code' => 'GRE-STACKS',
               'name' => 'Green Library Stacks',
               'campusName' => 'Stanford Libraries',
               'libraryName' => 'Cecil H. Green',
               'institutionName' => 'Stanford University' },
             'permanentLocation' =>
             { 'code' => 'GRE-STACKS',
               'name' => 'Green Library Stacks',
               'campusName' => 'Stanford Libraries',
               'libraryName' => 'Cecil H. Green',
               'institutionName' => 'Stanford University' },
             'temporaryLocation' => {} },
          'formerIds' => [],
          'callNumber' =>
           { 'typeId' => '95467209-6d7b-468b-94df-0f5d7ad2747d',
             'typeName' => 'Library of Congress classification',
             'callNumber' => 'SB270 .E8 A874 2007' },
          'copyNumber' => '1',
          'yearCaption' => [],
          'materialType' => 'book',
          'numberOfPieces' => '1',
          'electronicAccess' => [],
          'holdingsRecordId' => '9e7afebb-08a6-51f5-a8f2-ecf622757dd7',
          'statisticalCodes' =>
           [{ 'id' => 'e6f1059b-4ab2-4bb2-adcb-af66acb6f4fa',
              'code' => 'DIGI-SCAN',
              'name' => 'Item has been digitally scanned',
              'source' => 'local',
              'statisticalCodeType' => 'Item' }],
          'permanentLoanType' => 'Can circulate',
          'suppressFromDiscovery' => false }
      end

      it { is_expected.to be_instance_of described_class }
    end
  end
end
