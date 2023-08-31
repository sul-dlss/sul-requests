# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CurrentLocationNote do
  let(:note) { described_class.new(holding) }

  let(:holding) do
    Folio::Item.new(
      barcode: '123',
      type: 'LC',
      callnumber: '456',
      material_type: 'book',
      permanent_location: nil,
      effective_location: nil,
      status:
    )
  end
  let(:status) { 'Available' }

  context 'by default' do
    it { expect(note).not_to be_present }
    it { expect(note.to_s).to be_blank }
  end

  context 'when CHECKEDOUT' do
    let(:status) { 'Checked out' }

    it { expect(note).to be_present }
    it { expect(note.to_s).to start_with 'This item is currently in use by another patron' }
  end

  context 'when being processed' do
    let(:status) { 'In process' }

    it { expect(note).to be_present }
    it { expect(note.to_s).to start_with 'We\'re currently processing this item for use' }
  end

  context 'when missing' do
    let(:status) { 'Missing' }

    it { expect(note).to be_present }
    it { expect(note.to_s).to start_with 'We\'re currently searching for this missing item' }
  end

  context 'when at a loan desk' do
    let(:status) { 'Awaiting pickup' }

    it { expect(note).to be_present }
    it { expect(note.to_s).to start_with 'This item is currently being held for use by another patron' }
  end
end
