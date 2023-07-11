# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Mediateable' do
  subject(:request) { build(:request) }

  describe '#Mediateable?' do
    it 'is false if the item does not have the scannable attributes' do
      expect(subject).not_to be_mediateable
    end

    it 'returns true if the item is in SPEC-COLL' do
      subject.origin = 'SPEC-COLL'
      expect(subject).to be_mediateable
    end

    it 'returns true if the item is in RUMSEYMAP' do
      subject.origin = 'RUMSEYMAP'
      expect(subject).to be_mediateable
    end

    it 'returns true if the item is in SAL3 and PAGE-MP location' do
      subject.origin = 'SAL3'
      subject.origin_location = 'PAGE-MP'
      expect(subject).to be_mediateable
    end

    describe 'ART Locked Stacks' do
      it 'returns true if the item is in a locked stacks location within ART' do
        subject.origin = 'ART'
        subject.origin_location = 'ARTLCKO'
        expect(subject).to be_mediateable
      end

      it 'returns false if the item is in a non-locked stacks location within ART' do
        subject.origin = 'ART'
        subject.origin_location = 'STACKS'
        expect(subject).not_to be_mediateable
      end
    end
  end
end
