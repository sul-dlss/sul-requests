require 'rails_helper'

describe User do
  describe '#webauth_user?' do
    it 'should return false when the user has no WebAuth attribute' do
      expect(subject).to_not be_webauth_user
    end
    it 'should return true when the user has a WebAuth attribute' do
      subject.webauth = 'WebAuth User'
      expect(subject).to be_webauth_user
    end
  end
end
