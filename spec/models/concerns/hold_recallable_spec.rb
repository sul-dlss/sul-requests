require 'rails_helper'

###
#  Stub test class for inlcuding HolDRecallable mixin
###
class HoldRecallableTestClass
  attr_accessor :request
  include HoldRecallable
end

describe HoldRecallable do
  let(:request) { build(:request) }
  let(:subject) { HoldRecallableTestClass.new }
  before do
    subject.request = request
  end
  describe '#HoldRecallable?' do
    it 'is true when a requested barcode is present' do
      request.requested_barcode = '3610512345'
      expect(subject).to be_hold_recallable
    end

    it 'is false when a requested barcode is not present' do
      expect(subject).not_to be_hold_recallable
    end
  end
end
