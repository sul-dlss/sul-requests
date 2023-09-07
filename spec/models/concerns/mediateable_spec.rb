# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Mediateable' do
  subject(:request) { build(:request) }

  describe '#Mediateable?' do
    it 'is false if the item does not have the scannable attributes' do
      expect(subject).not_to be_mediateable
    end

    it 'returns true if the item is in SAL3-PAGE-MP location' do
      subject.location = 'SAL3-PAGE-MP'
      subject.bib_data = build(:page_mp_holdings)
      expect(subject).to be_mediateable
    end

    describe 'ART Locked Stacks' do
      context 'when the item is in a locked stacks location' do
        before do
          subject.location = 'ART-LOCKED-LARGE'
          subject.bib_data = build(:single_mediated_holding)
        end

        it 'returns true' do
          expect(subject).to be_mediateable
        end
      end

      context 'when the item is in a non-locked stacks location' do
        before do
          subject.location = 'ART-STACKS'
          subject.bib_data = build(:art_stacks_holding)
        end

        it 'returns false' do
          expect(subject).not_to be_mediateable
        end
      end
    end
  end
end
