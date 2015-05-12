require 'rails_helper'

describe MediatedPage do
  it 'should have the properly assigned Rails STI attribute value' do
    expect(subject.type).to eq 'MediatedPage'
  end
  describe '#commentable?' do
    it 'should return true if the library is SPEC-COLL' do
      subject.origin = 'SPEC-COLL'
      expect(subject).to be_commentable
    end
    it 'should return false if the library is not SPEC-COLL' do
      subject.origin = 'HOOVER'
      expect(subject).to_not be_commentable
    end
  end
  describe 'TokenEncryptable' do
    it 'should mixin TokenEncryptable' do
      expect(subject).to be_kind_of TokenEncryptable
    end
    it 'should add the user email address to the token' do
      subject.user = build(:non_webauth_user)
      expect(subject.to_token).to match(/jstanford@stanford.edu$/)
    end
  end

  describe 'requestable' do
    it { is_expected.to be_requestable_by_all }
    it { is_expected.to be_requestable_with_library_id }
    it { is_expected.not_to be_requestable_with_sunet_only }

    describe 'for hopkins' do
      before { subject.origin = 'HOPKINS' }
      it { is_expected.not_to be_requestable_by_all }
      it { is_expected.not_to be_requestable_with_library_id }
      it { is_expected.to be_requestable_with_sunet_only }
    end
  end

  describe '#item_limit' do
    it 'should be nil for normal libraries' do
      expect(subject.item_limit).to be_nil
    end

    it 'should be 5 for items from SPEC-COLL' do
      subject.origin = 'SPEC-COLL'
      expect(subject.item_limit).to eq 5
    end
  end
end
