require 'rails_helper'

###
#  Stub test class for inlcuding Scannable mixin
###
class ScannableTestClass
  attr_accessor :library, :location
  include Scannable
end

describe Scannable do
  let(:subject) { ScannableTestClass.new }
  describe '#scannable?' do
    it 'should be false if the item does not have the scannable attributes' do
      expect(subject).to_not be_scannable
    end
    it 'should return true if the library is SAL3 and the location in STACKS' do
      subject.library = 'SAL3'
      subject.location = 'STACKS'
      expect(subject).to be_scannable
    end
  end
end
