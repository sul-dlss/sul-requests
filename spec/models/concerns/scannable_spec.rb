# frozen_string_literal: true

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

      it 'is true for particular SAL3 locations' do
        subject.library = 'SAL3'
        subject.location = 'STACKS'
        expect(subject).to be_scannable

        subject.location = 'PAGE-GR'
        expect(subject).to be_scannable

        subject.location = 'BUS-STACKS'
        expect(subject).to be_scannable
      end

      it 'is true for particular SAL1/2 locations' do
        subject.library = 'SAL'
        subject.location = 'STACKS'
        expect(subject).to be_scannable

        subject.location = 'ND-PAGE-EA'
        expect(subject).to be_scannable

        subject.location = 'NOT-STACKS'
        expect(subject).not_to be_scannable
      end

      it 'is false when library or location is not scannable' do
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
      let(:page_gr_scannable_items) { [double(type: 'NH-INHOUSE')] }

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

      it 'is true for special PAGE-GR locations' do
        subject.location = 'PAGE-GR'
        subject.request = double('request', holdings: page_gr_scannable_items)
        expect(subject).to be_scannable
      end
    end
  end
end
