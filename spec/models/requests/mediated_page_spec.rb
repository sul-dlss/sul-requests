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
end
