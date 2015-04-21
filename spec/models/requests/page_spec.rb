require 'rails_helper'

describe Page do
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
