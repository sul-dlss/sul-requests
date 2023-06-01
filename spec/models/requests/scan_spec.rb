# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Scan do
  let(:folio_holding_response) do
    { 'instanceId' => 'f1c52ab3-721e-5234-9a00-1023e034e2e8',
      'source' => 'MARC',
      'modeOfIssuance' => 'single unit',
      'natureOfContent' => [],
      'holdings' => [],
      'items' =>
       [{ 'id' => '584baef9-ea2f-5ff5-9947-bbc348aee4a4',
          'notes' => [],
          'status' => 'Available',
          'barcode' => '3610512345678',
          'location' =>
          { 'effectiveLocation' => { 'code' => 'SAL-TEMP' },
            'permanentLocation' => { 'code' => 'SAL-TEMP' },
            'temporaryLocation' => {} },
          'callNumber' =>
            { 'typeId' => '6caca63e-5651-4db6-9247-3205156e9699', 'typeName' => 'Other scheme', 'callNumber' => 'ABC 123' },
          'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
          'materialType' => 'periodical',
          'permanentLoanType' => 'Can circulate',
          'suppressFromDiscovery' => false },
        { 'id' => '99466f50-2b8c-51d4-8890-373190b8f6c4',
          'notes' => [],
          'status' => 'Available',
          'barcode' => '3610587654321',
          'location' =>
          { 'effectiveLocation' => { 'code' => 'SAL-TEMP' },
            'permanentLocation' => { 'code' => 'SAL-TEMP' },
            'temporaryLocation' => {} },
          'callNumber' =>
            { 'typeId' => '6caca63e-5651-4db6-9247-3205156e9699', 'typeName' => 'Other scheme', 'callNumber' => 'ABC 321' },
          'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
          'materialType' => 'periodical',
          'permanentLoanType' => 'Can circulate',
          'suppressFromDiscovery' => false }] }
  end

  before do
    allow_any_instance_of(FolioClient).to receive(:find_instance).and_return({ indexTitle: 'Item Title' })
    allow_any_instance_of(FolioClient).to receive(:resolve_to_instance_id).and_return('f1c52ab3-721e-5234-9a00-1023e034e2e8')
    allow_any_instance_of(FolioClient).to receive(:items_and_holdings).and_return(folio_holding_response)
  end

  it 'has the properly assigned Rails STI attribute value' do
    expect(subject.type).to eq 'Scan'
  end

  it 'validates based on if the item is scannable or not' do
    expect do
      described_class.create!(item_id: '1234',
                              origin: 'GREEN',
                              origin_location: 'STACKS',
                              section_title: 'Some chapter title')
    end.to raise_error(
      ActiveRecord::RecordInvalid, 'Validation failed: This item is not scannable'
    )
  end

  it 'allows scannable only materials to be requested for scan' do
    stub_searchworks_api_json(build(:scannable_only_holdings))

    expect do
      described_class.create!(
        item_id: '123456',
        origin: 'SAL',
        origin_location: 'SAL-TEMP',
        section_title: 'Chapter 1'
      )
    end.not_to raise_error
  end

  describe 'requestable' do
    it { is_expected.not_to be_requestable_with_name_email }
    it { is_expected.not_to be_requestable_with_library_id }
  end

  describe '#item_limit' do
    it 'is 1' do
      expect(subject.item_limit).to eq 1
    end
  end

  describe '#submit!' do
    it 'submits the request to ILLIAD' do
      expect(SubmitScanRequestJob).to receive(:perform_later)
      subject.submit!
    end
  end

  describe 'send_approval_status!' do
    describe 'for library id users' do
      let(:subject) { create(:scan, :without_validations, user: create(:library_id_user)) }

      it 'does not send an approval status email' do
        expect do
          subject.send_approval_status!
        end.not_to have_enqueued_mail
      end
    end

    describe 'for everybody else' do
      let(:subject) { create(:scan, :without_validations, user: create(:sso_user)) }

      it 'sends an approval status email' do
        expect do
          subject.send_approval_status!
        end.to have_enqueued_mail(RequestStatusMailer)
      end
    end
  end
end
