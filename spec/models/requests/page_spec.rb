# frozen_string_literal: true

require 'rails_helper'

describe Page do
  describe 'TokenEncryptable' do
    it 'mixins TokenEncryptable' do
      expect(subject).to be_kind_of TokenEncryptable
    end
    it 'adds the user email address to the token' do
      subject.user = build(:non_webauth_user)
      expect(subject.to_token).to match(/jstanford@stanford.edu$/)
    end
  end

  describe 'validation' do
    it 'does not allow mediated pages to be created' do
      expect(
        lambda {
          described_class.create!(
            item_id: '1234',
            origin: 'SPEC-COLL',
            origin_location: 'STACKS',
            destination: 'SPEC-COLL'
          )
        }
      ).to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: This item is not pageable')
    end

    it 'does not not allow pages to be created with destinations that are not valid pickup libraries of their origin' do
      expect(
        -> { described_class.create!(item_id: '1234', origin: 'ARS', origin_location: 'STACKS', destination: 'GREEN') }
      ).to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Destination is not a valid pickup library')
    end
  end

  describe 'requestable' do
    context 'Media Microtext' do
      before { subject.origin = 'MEDIA-MTXT' }

      it { is_expected.not_to be_requestable_by_all }
      it { is_expected.to be_requestable_with_library_id }
      it { is_expected.not_to be_requestable_with_sunet_only }
      it { is_expected.not_to be_requires_additional_user_validation }
    end

    context 'other libraries' do
      it { is_expected.to be_requestable_by_all }
      it { is_expected.to be_requestable_with_library_id }
      it { is_expected.not_to be_requestable_with_sunet_only }
      it { is_expected.to be_requires_additional_user_validation }
    end
  end

  it 'has the properly assigned Rails STI attribute value' do
    expect(subject.type).to eq 'Page'
  end

  describe 'send_confirmation!' do
    let(:subject) { create(:page, user: create(:webauth_user)) }

    it 'returns true' do
      expect(
        -> { subject.send_confirmation! }
      ).not_to change { ConfirmationMailer.deliveries.count }
      expect(subject.send_confirmation!).to be true
    end
  end

  describe 'send_approval_status!' do
    describe 'for library id users' do
      let(:subject) { create(:page, user: create(:library_id_user)) }

      it 'does not send an approval status email' do
        expect(
          -> { subject.send_approval_status! }
        ).not_to change { ApprovalStatusMailer.deliveries.count }
      end
    end

    describe 'for everybody else' do
      let(:subject) { create(:page, user: create(:webauth_user)) }

      it 'sends an approval status email' do
        expect(
          -> { subject.send_approval_status! }
        ).to change { ApprovalStatusMailer.deliveries.count }.by(1)
      end
    end
  end
end
