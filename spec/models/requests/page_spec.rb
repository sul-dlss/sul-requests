# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Page do
  before do
    allow_any_instance_of(FolioClient).to receive(:find_instance).and_return({ indexTitle: 'Item Title' })
    allow_any_instance_of(FolioClient).to receive(:resolve_to_instance_id).and_return('f1c52ab3-721e-5234-9a00-1023e034e2e8')
    allow_any_instance_of(FolioClient).to receive(:items_and_holdings).and_return(folio_holding_response)
  end

  let(:folio_holding_response) do
    { 'instanceId' => 'f1c52ab3-721e-5234-9a00-1023e034e2e8',
      'source' => 'MARC',
      'modeOfIssuance' => 'single unit',
      'natureOfContent' => [],
      'holdings' => [],
      'items' =>
       [{ 'id' => '584baef9-ea2f-5ff5-9947-bbc348aee4a4',
          'status' => 'Available',
          'barcode' => '3610512345678',
          'location' =>
          { 'effectiveLocation' => { 'code' => 'GRE-STACKS' },
            'permanentLocation' => { 'code' => 'GRE-STACKS' },
            'temporaryLocation' => {} },
          'callNumber' =>
            { 'typeId' => '6caca63e-5651-4db6-9247-3205156e9699', 'typeName' => 'Other scheme', 'callNumber' => 'ABC 123' },
          'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
          'materialType' => 'book',
          'permanentLoanType' => 'Can circulate',
          'suppressFromDiscovery' => false },
        { 'id' => '99466f50-2b8c-51d4-8890-373190b8f6c4',
          'status' => 'Available',
          'barcode' => '3610587654321',
          'location' =>
          { 'effectiveLocation' => { 'code' => 'GRE-STACKS' },
            'permanentLocation' => { 'code' => 'GRE-STACKS' },
            'temporaryLocation' => {} },
          'callNumber' =>
            { 'typeId' => '6caca63e-5651-4db6-9247-3205156e9699', 'typeName' => 'Other scheme', 'callNumber' => 'ABC 321' },
          'holdingsRecordId' => 'd1d495e8-7436-540b-a55a-5dfccfba25a3',
          'materialType' => 'book',
          'permanentLoanType' => 'Can circulate',
          'suppressFromDiscovery' => false }] }
  end

  describe 'TokenEncryptable' do
    it 'mixins TokenEncryptable' do
      expect(subject).to be_kind_of TokenEncryptable
    end

    it 'adds the user email address to the token' do
      subject.user = build(:non_sso_user)
      expect(subject.to_token(version: 1)).to match(/jstanford@stanford.edu$/)
    end
  end

  describe 'validation' do
    it 'does not allow mediated pages to be created' do
      expect do
        described_class.create!(
          item_id: '1234',
          origin: 'ART',
          origin_location: 'ARTLCKL',
          destination: 'ART'
        )
      end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: This item is not pageable')
    end

    it 'does not not allow pages to be created with destinations that are not valid pickup libraries of their origin' do
      expect do
        described_class.create!(item_id: '1234', origin: 'ARS', origin_location: 'STACKS', destination: 'GREEN')
      end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Destination is not a valid pickup library')
    end
  end

  describe 'requestable' do
    context 'Media Microtext' do
      before { subject.origin = 'MEDIA-MTXT' }

      it { is_expected.not_to be_requestable_with_name_email }
      it { is_expected.to be_requestable_with_library_id }
    end

    context 'other libraries' do
      it { is_expected.to be_requestable_with_name_email }
      it { is_expected.to be_requestable_with_library_id }
    end
  end

  it 'has the properly assigned Rails STI attribute value' do
    expect(subject.type).to eq 'Page'
  end

  describe 'library id validation', allow_apis: true do
    let(:user) { create(:library_id_user) }
    let(:subject) do
      described_class.create(
        origin: 'MEDIA-MTXT',
        origin_location: 'MM-STACKS',
        destination: 'GREEN',
        item_id: 'abc123',
        user:
      )
    end

    before do
      expect(Symphony::Patron).to receive(:find_by).with(library_id: user.library_id).at_least(:once).and_return(
        double(exists?: user_exists)
      )
    end

    context 'when the library ID exists' do
      let(:user_exists) { true }

      it { expect(subject).to be_valid }
    end

    context 'when the library ID does not exist' do
      let(:user_exists) { false }

      it { expect(subject).not_to be_valid }
    end
  end

  describe 'send_approval_status!' do
    subject(:request) { create(:page, user:) }

    let(:user) {}

    before do
      allow(Symphony::Patron).to receive(:find_by).with(library_id: user.library_id).and_return(
        instance_double(Symphony::Patron, exists?: true, email: '')
      )
    end

    describe 'for library id users' do
      let(:user) { create(:library_id_user) }

      it 'does not send an approval status email' do
        expect do
          subject.send_approval_status!
        end.not_to have_enqueued_mail
      end
    end

    describe 'for everybody else' do
      let(:user) { create(:sso_user) }

      it 'sends an approval status email' do
        expect do
          subject.send_approval_status!
        end.to have_enqueued_mail(RequestStatusMailer)
      end
    end
  end
end
