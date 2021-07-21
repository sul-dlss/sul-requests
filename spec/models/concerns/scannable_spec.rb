# frozen_string_literal: true

require 'rails_helper'

###
#  Stub test class for including Scannable mixin
###
class ScannableTestClass
  attr_accessor :request, :library, :location

  include ActiveModel::Model
  include Scannable
end

describe Scannable do
  subject { ScannableTestClass.new(request: request, library: library, location: location) }

  let(:request) { double(:request, holdings: [double(type: item_type)]) }
  let(:library) { 'SAL3' }
  let(:location) { 'STACKS' }
  let(:item_type) { 'STKS' }

  describe '#scannable?' do
    it 'is true for scannable items in particular SAL3 locations' do
      subject.location = 'STACKS'
      expect(subject).to be_scannable

      subject.location = 'PAGE-GR'
      expect(subject).to be_scannable

      subject.location = 'BUS-STACKS'
      expect(subject).to be_scannable
    end

    it 'is true for scannable items in particular SAL 1/2 locations' do
      subject.library = 'SAL'
      subject.location = 'STACKS'
      expect(subject).to be_scannable

      subject.location = 'ND-PAGE-EA'
      expect(subject).to be_scannable
    end

    it 'is false when the location is not scannable' do
      subject.library = 'SAL'
      subject.location = 'NOT-STACKS'
      expect(subject).not_to be_scannable
    end

    it 'is false when the library is not scannable' do
      subject.library = 'NOT-SAL3'
      subject.location = 'STACKS'
      expect(subject).not_to be_scannable
    end

    context 'when there are no scannable items in the location' do
      let(:item_type) { 'NOT-STKS' }

      it 'is false' do
        expect(subject).not_to be_scannable
      end
    end

    context 'for some page-gr item types' do
      let(:library) { 'SAL3' }
      let(:location) { 'PAGE-GR' }
      let(:item_type) { 'NH-INHOUSE' }

      it 'is true' do
        expect(subject).to be_scannable
      end
    end
  end

  describe '#scannable_only?' do
    it 'is true a scannable only library/location has scannable only items' do
      subject.library = 'SAL'
      subject.location = 'SAL-TEMP'
      subject.request = double('request', holdings: [double(type: 'NONCIRC')])

      expect(subject).to be_scannable_only
    end

    it 'is false when not scannable only library/location' do
      subject.library = 'SAL'
      subject.location = 'STACKS'
      subject.request = double('request', holdings: [double(type: 'NONCIRC')])

      expect(subject).not_to be_scannable_only
    end

    it 'is false when a circulating item is in the scannable only library/location' do
      subject.library = 'SAL'
      subject.location = 'SAL-TEMP'
      subject.request = double('request', holdings: [double(type: 'STKS')])

      expect(subject).not_to be_scannable_only
    end
  end
end
