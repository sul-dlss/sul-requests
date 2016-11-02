require 'rails_helper'

###
#  Stub test class for including Mediateable mixin
###
class MediateableTestClass
  attr_accessor :library, :location
  include Mediateable
end

describe Mediateable do
  let(:subject) { MediateableTestClass.new }
  describe '#Mediateable?' do
    it 'should be false if the item does not have the scannable attributes' do
      expect(subject).to_not be_mediateable
    end
    it 'should return true if the item is in SPEC-COLL' do
      subject.library = 'SPEC-COLL'
      expect(subject).to be_mediateable
    end

    it 'should return true if the item is in RUMSEYMAP' do
      subject.library = 'RUMSEYMAP'
      expect(subject).to be_mediateable
    end

    it 'should return true if the item is in SAL3 and PAGE-MP location' do
      subject.library = 'SAL3'
      subject.location = 'PAGE-MP'
      expect(subject).to be_mediateable
    end
    describe 'HOPKINS' do
      before { subject.library = 'HOPKINS' }
      it 'should return true if the item is in the STACKS location' do
        subject.location = 'STACKS'
        expect(subject).to be_mediateable
      end
      it 'should return false if the item is not in the STACKS location' do
        subject.location = 'SOMEWHERE-ELSE'
        expect(subject).to_not be_mediateable
      end
    end
    describe 'HV-ARCHIVE' do
      before { subject.library = 'HV-ARCHIVE' }
      it 'should return true if the item is in a *-30 location' do
        subject.location = 'SOMEWHERE-30'
        expect(subject).to be_mediateable
      end
      it 'should return false if the item is not in a *-30 location' do
        subject.location = 'SOMEWHERE-ELSE'
        expect(subject).not_to be_mediateable
      end
    end
  end
end
