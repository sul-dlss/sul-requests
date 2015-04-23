require 'rails_helper'

describe Page do
  describe 'TokenEncryptable' do
    it 'should mixin TokenEncryptable' do
      expect(subject).to be_kind_of TokenEncryptable
    end
    it 'should add the user email address to the token' do
      subject.user = User.new(email: 'jstanford@stanford.edu')
      expect(subject.to_token).to match(/jstanford@stanford.edu$/)
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
  it 'should have the properly assigned Rails STI attribute value' do
    expect(subject.type).to eq 'Page'
  end
end
