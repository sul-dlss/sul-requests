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
        -> { Page.create!(item_id: '1234', origin: 'SPEC-COLL', origin_location: 'STACKS') }
      ).to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: This item is not pageable')
    end
  end

  describe '#commentable?' do
    it 'should be false if the library is not a commentable library' do
      expect(subject).to_not be_commentable
    end
    it 'should be true if the library is a commentable library' do
      subject.origin = 'SAL-NEWARK'
      expect(subject).to be_commentable
    end
  end

  describe 'requestable' do
    it { is_expected.to be_requestable_by_all }
    it { is_expected.to be_requestable_with_library_id }
    it { is_expected.not_to be_requestable_with_sunet_only }
  end

  it 'should have the properly assigned Rails STI attribute value' do
    expect(subject.type).to eq 'Page'
  end
end
