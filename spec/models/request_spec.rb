require 'rails_helper'

describe Request do
  describe 'validations' do
    it 'should require the basic set of information to be present' do
      expect(-> { Request.create! }).to raise_error(ActiveRecord::RecordInvalid)
      expect(-> { Request.create!(item_id: '1234', origin: 'GREEN') }).to raise_error(ActiveRecord::RecordInvalid)
      expect(-> { Request.create! }).to raise_error(ActiveRecord::RecordInvalid)
      expect(-> { Request.create! }).to raise_error(ActiveRecord::RecordInvalid)
    end
  end
  describe '#new_request?' do
    it 'should return false if the status is not present' do
      expect(subject).to_not be_new_request
    end
    it 'should return true if the status is present' do
      subject.status = 'anything'
      expect(subject).to be_new_request
    end
  end
  describe '#scannable?' do
    it 'should be scannable if it is a SAL3 item in the STACKS location' do
      subject.origin = 'SAL3'
      subject.origin_location = 'STACKS'
      expect(subject).to be_scannable
    end
    it 'should not be scannable if it is not in the corect location and library' do
      expect(subject).to_not be_scannable
    end
  end
end
