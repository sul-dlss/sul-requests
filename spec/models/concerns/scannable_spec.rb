# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Scannable' do
  subject(:request) { build(:request, origin: library, origin_location: location, bib_data:) }

  let(:library) { 'SAL3' }
  let(:location) { 'STACKS' }
  let(:item_type) { 'STKS' }
  let(:bib_data) { build(:scannable_holdings) }

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
  end
end
