# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CurrentLocationNote do
  let(:current_location) { nil }
  let(:note) { described_class.new(current_location) }

  context 'by default' do
    it { expect(note).not_to be_present }
    it { expect(note.to_s).to be_blank }
  end

  context 'when CHECKEDOUT' do
    let(:current_location) { 'CHECKEDOUT' }

    it { expect(note).to be_present }
    it { expect(note.to_s).to start_with 'This item is currently in use by another patron' }
  end

  context 'when being processed' do
    let(:current_location) { described_class::BEING_PROCESSED_LOCATIONS.sample }

    it { expect(note).to be_present }
    it { expect(note.to_s).to start_with 'We\'re currently processing this item for use' }
  end
end
