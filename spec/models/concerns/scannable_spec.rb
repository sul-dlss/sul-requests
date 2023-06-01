# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Scannable' do
  subject(:request) { build(:request, origin: library, origin_location: location) }

  let(:library) { 'SAL3' }
  let(:location) { 'STACKS' }
  let(:item_type) { 'STKS' }

  before do
    allow(request).to receive(:holdings).and_return([double(type: item_type)])
  end

  describe '#scannable?' do
    it 'is true for scannable items in particular SAL3 locations' do
      subject.origin_location = 'STACKS'
      expect(subject).to be_scannable

      subject.origin_location = 'PAGE-GR'
      expect(subject).to be_scannable

      subject.origin_location = 'BUS-STACKS'
      expect(subject).to be_scannable
    end

    it 'is true for scannable items in particular SAL 1/2 locations' do
      subject.origin = 'SAL'
      subject.origin_location = 'STACKS'
      expect(subject).to be_scannable

      subject.origin_location = 'ND-PAGE-EA'
      expect(subject).to be_scannable
    end

    context 'when the location is not scannable' do
      before do
        request.origin = 'SAL'
        request.origin_location = 'NOT-STACKS'
      end

      it { is_expected.not_to be_scannable }
    end

    it 'is false when the library is not scannable' do
      subject.origin = 'NOT-SAL3'
      subject.origin_location = 'STACKS'
      expect(subject).not_to be_scannable
    end

    # FOLIO doesn't have item_type to filter by
    context 'when there are no scannable items in the location', if: Settings.ils.bib_model != 'Folio::BibData' do
      let(:item_type) { 'NOT-STKS' }

      it 'is false' do
        expect(subject).not_to be_scannable
      end
    end

    # FOLIO doesn't have item_type to filter by
    context 'for some page-gr item types', if: Settings.ils.bib_model != 'Folio::BibData' do
      let(:library) { 'SAL3' }
      let(:location) { 'PAGE-GR' }
      let(:item_type) { 'NH-INHOUSE' }

      it 'is true' do
        expect(subject).to be_scannable
      end
    end
  end

  # FOLIO doesn't have item_type to filter by
  describe '#scannable_only?', if: Settings.ils.bib_model != 'Folio::BibData' do
    it 'is true a scannable only library/location has scannable only items' do
      subject.origin = 'SAL'
      subject.origin_location = 'SAL-TEMP'
      allow(request).to receive(:holdings).and_return([double(type: 'NONCIRC')])

      expect(subject).to be_scannable_only
    end

    it 'is false when not scannable only library/location' do
      subject.origin = 'SAL'
      subject.origin_location = 'STACKS'
      allow(request).to receive(:holdings).and_return([double(type: 'NONCIRC')])

      expect(subject).not_to be_scannable_only
    end

    context 'when a circulating item is in the scannable only library/location' do
      it 'is false' do
        subject.origin = 'SAL'
        subject.origin_location = 'SAL-TEMP'
        allow(request).to receive(:holdings).and_return([double(type: 'STKS')])

        expect(subject).not_to be_scannable_only
      end
    end
  end
end
