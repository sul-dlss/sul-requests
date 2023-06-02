# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CurrentLocationNote do
  let(:note) { described_class.new(holding) }
  let(:holding) { instance_double(Searchworks::HoldingItem, checked_out?: false, hold?: false, missing?: false, processing?: false) }

  context 'by default' do
    it { expect(note).not_to be_present }
    it { expect(note.to_s).to be_blank }
  end

  context 'when CHECKEDOUT' do
    let(:holding) { instance_double(Searchworks::HoldingItem, checked_out?: true, hold?: false, missing?: false, processing?: false) }

    it { expect(note).to be_present }
    it { expect(note.to_s).to start_with 'This item is currently in use by another patron' }
  end

  context 'when being processed' do
    let(:holding) { instance_double(Searchworks::HoldingItem, checked_out?: false, hold?: false, missing?: false, processing?: true) }

    it { expect(note).to be_present }
    it { expect(note.to_s).to start_with 'We\'re currently processing this item for use' }
  end

  context 'when missing' do
    let(:holding) { instance_double(Searchworks::HoldingItem, checked_out?: false, hold?: false, missing?: true, processing?: false) }

    it { expect(note).to be_present }
    it { expect(note.to_s).to start_with 'We\'re currently searching for this missing item' }
  end

  context 'when at a loan desk' do
    let(:holding) { instance_double(Searchworks::HoldingItem, checked_out?: false, hold?: true, missing?: false, processing?: false) }

    it { expect(note).to be_present }
    it { expect(note.to_s).to start_with 'This item is currently being held for use by another patron' }
  end
end
