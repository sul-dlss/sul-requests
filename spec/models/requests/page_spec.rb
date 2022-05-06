# frozen_string_literal: true

require 'rails_helper'

describe Page do
  describe 'TokenEncryptable' do
    it 'mixins TokenEncryptable' do
      expect(subject).to be_kind_of TokenEncryptable
    end

    it 'adds the user email address to the token' do
      subject.user = build(:non_webauth_user)
      expect(subject.to_token(version: 1)).to match(/jstanford@stanford.edu$/)
    end
  end

  describe 'validation' do
    it 'does not allow mediated pages to be created' do
      expect do
        described_class.create!(
          item_id: '1234',
          origin: 'SPEC-COLL',
          origin_location: 'STACKS',
          destination: 'SPEC-COLL'
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
        user: user
      )
    end

    before do
      expect(Patron).to receive(:find_by).with(library_id: user.library_id).at_least(:once).and_return(
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
    subject(:request) { create(:page, user: user) }

    let(:user) {}

    before do
      allow(Patron).to receive(:find_by).with(library_id: user.library_id).and_return(
        instance_double(Patron, exists?: true, email: '')
      )
    end

    describe 'for library id users' do
      let(:user) { create(:library_id_user) }

      it 'does not send an approval status email' do
        expect do
          subject.send_approval_status!
        end.not_to change { RequestStatusMailer.deliveries.count }
      end
    end

    describe 'for everybody else' do
      let(:user) { create(:webauth_user) }

      it 'sends an approval status email' do
        expect do
          subject.send_approval_status!
        end.to change { RequestStatusMailer.deliveries.count }.by(1)
      end
    end
  end
end
