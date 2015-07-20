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
    it 'is false by default' do
      expect(subject).not_to be_hold_recallable
    end

    describe 'when a barcode is provided' do
      it 'is true' do
        request.requested_barcode = '3610512345'
        expect(subject).to be_hold_recallable
      end
    end

    describe 'when INPROCESS' do
      it 'is true when the origin_location is INPROCESS' do
        request.origin_location = 'INPROCESS'
        expect(request).to be_hold_recallable
      end

      it 'is true when the current location is INPROCESS' do
        allow(request).to receive_messages(holdings: [
          double('holding', current_location: double('location', code: 'INPROCESS'))
        ])

        expect(request).to be_hold_recallable
      end
    end

    describe 'when ON-ORDER' do
      it 'is true when the origin_location is ON-ORDER' do
        request.origin_location = 'ON-ORDER'
        expect(request).to be_hold_recallable
      end

      it 'is true when the current location is ON-ORDER' do
        allow(request).to receive_messages(holdings: [
          double('holding', current_location: double('location', code: 'ON-ORDER'))
        ])

        expect(request).to be_hold_recallable
      end
    end
  end
end
