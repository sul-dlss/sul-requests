# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Folio::PickupDestination do
  let(:pickup_destination) { described_class.new('GREEN-LOAN') }

  describe '#display_label' do
    subject { pickup_destination.display_label }

    it { is_expected.to eq 'Green Library' }
  end

  describe '#library_code' do
    subject { pickup_destination.library_code }

    it { is_expected.to eq 'GREEN' }
  end
end
