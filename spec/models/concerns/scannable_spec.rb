require 'rails_helper'

###
#  Stub test class for including Scannable mixin
###
class ScannableTestClass
  attr_accessor :request, :library, :location
  include Scannable
end

describe Scannable do
  let(:request) { build(:request) }
  let(:subject) { ScannableTestClass.new }
  before do
    subject.request = request
  end
  describe '#scannable?' do
    describe 'library and location' do
      before do
        allow(subject).to receive_messages(includes_scannable_item?: true)
      end

      it 'is true when from SAL3 + STACKS' do
        subject.library = 'SAL3'
        subject.location = 'STACKS'
        expect(subject).to be_scannable
      end

      it 'is true when from SAL3 + BUS-STACKS' do
        subject.library = 'SAL3'
        subject.location = 'BUS-STACKS'
        expect(subject).to be_scannable
      end

      it 'is false when library or location is not SAL3 or STACKS' do
        subject.library = 'NOT-SAL3'
        subject.location = 'STACKS'
        expect(subject).to_not be_scannable
        subject.library = 'SAL3'
        subject.location = 'NOT-STACKS'
        expect(subject).to_not be_scannable
      end
    end

    describe 'holdings' do
      let(:scannable_items) { [double(type: 'STKS')] }
      let(:unscannable_items) { [double(type: 'NOT-STKS')] }
      before do
        allow(subject).to receive_messages(scannable_library?: true)
        allow(subject).to receive_messages(scannable_location?: true)
      end

      it 'is true when there are scannable items in the location' do
        subject.request = double('request', holdings: scannable_items)
        expect(subject).to be_scannable
      end

      it 'is false when there are no scannable items in the location' do
        subject.request = double('request', holdings: unscannable_items)
        expect(subject).to_not be_scannable
      end

      it 'is true when there are mixed items in the location' do
        subject.request = double('request', holdings: [scannable_items, unscannable_items].flatten)
        expect(subject).to be_scannable
      end
    end
  end
end
