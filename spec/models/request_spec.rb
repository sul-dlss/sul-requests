require 'rails_helper'

describe Request do
  describe '#new_request?' do
    it 'should return false if the status is not present' do
      expect(subject).to_not be_new_request
    end
    it 'should return true if the status is present' do
      subject.status = 'anything'
      expect(subject).to be_new_request
    end
  end
end
