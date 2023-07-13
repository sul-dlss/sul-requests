# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Scannable' do
  subject(:request) { build(:request, origin: library, origin_location: location, bib_data:) }

  let(:library) { 'SAL3' }
  let(:location) { 'STACKS' }
  let(:item_type) { 'STKS' }
  let(:bib_data) { build(:scannable_holdings) }

  before do
    allow(request).to receive(:holdings).and_return([double(type: item_type)]) unless Settings.ils.bib_model == 'Folio::Instance'
  end

  describe '#scannable?' do
    it 'is true for scannable items in particular SAL3 locations' do
      expect(subject).to be_scannable
    end

    context 'for SAL1/2 locations' do
      let(:library) { 'SAL' }
      let(:location) { 'SAL-TEMP' }
      let(:bib_data) { build(:scannable_only_holdings) }

      it 'is true for scannable items in particular SAL 1/2 locations' do
        expect(subject).to be_scannable
      end
    end

    context 'when the location is not scannable' do
      let(:location) { 'PAGE-LP' }
      let(:bib_data) { build(:page_lp_holdings) }

      it { is_expected.not_to be_scannable }
    end

    # FOLIO doesn't have item_type to filter by
    context 'when there are no scannable items in the location', unless: Settings.ils.bib_model == 'Folio::Instance' do
      let(:item_type) { 'NOT-STKS' }

      it 'is false' do
        expect(subject).not_to be_scannable
      end
    end

    # FOLIO doesn't have item_type to filter by
    context 'for some page-gr item types', unless: Settings.ils.bib_model == 'Folio::Instance' do
      let(:library) { 'SAL3' }
      let(:location) { 'PAGE-GR' }
      let(:item_type) { 'NH-INHOUSE' }

      it 'is true' do
        expect(subject).to be_scannable
      end
    end
  end

  # FOLIO doesn't have item_type to filter by
  describe '#scannable_only?', unless: Settings.ils.bib_model == 'Folio::Instance' do
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
