# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Mediateable' do
  subject(:request) { build(:request) }

  describe '#Mediateable?' do
    it 'is false if the item does not have the scannable attributes' do
      expect(subject).not_to be_mediateable
    end

    it 'returns true if the item is in SAL3 and PAGE-MP location' do
      subject.origin = 'SAL3'
      subject.origin_location = 'PAGE-MP'
      subject.bib_data = build(:page_mp_holdings)
      expect(subject).to be_mediateable
    end

    describe 'ART Locked Stacks' do
      it 'returns true if the item is in a locked stacks location within ART' do
        subject.origin = 'ART'
        subject.origin_location = 'ARTLCKL'
        subject.bib_data = build(:single_mediated_holding)
        expect(subject).to be_mediateable
      end

      it 'returns false if the item is in a non-locked stacks location within ART' do
        subject.origin = 'ART'
        subject.origin_location = 'STACKS'
        subject.bib_data = build(:art_stacks_holding)
        expect(subject).not_to be_mediateable
      end
    end
  end
end
