require 'rails_helper'

describe Page do
  describe 'TokenEncryptable' do
    it 'should mixin TokenEncryptable' do
      expect(subject).to be_kind_of TokenEncryptable
    end
    it 'should add the user email address to the token' do
      subject.user = build(:non_webauth_user)
      expect(subject.to_token).to match(/jstanford@stanford.edu$/)
    end
  end

  describe 'validation' do
    it 'should not allow mediated pages to be created' do
      expect(
        -> { Page.create!(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS', destination: 'SPEC-COLL') }
      ).to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: This item is not pageable')
    end

    it 'does not not allow pages to be created with destinations that are not valid pickup libraries of their origin' do
      expect(
        -> { Page.create!(item_id: '1234', origin: 'ARS', origin_location: 'STACKS', destination: 'GREEN') }
      ).to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Destination is not a valid pickup library')
    end
  end

  describe 'requestable' do
    it { is_expected.to be_requestable_by_all }
    it { is_expected.to be_requestable_with_library_id }
    it { is_expected.not_to be_requestable_with_sunet_only }
    it { is_expected.to be_requires_additional_user_validation }
  end

  it 'should have the properly assigned Rails STI attribute value' do
    expect(subject.type).to eq 'Page'
  end
end
