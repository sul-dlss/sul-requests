# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Symphony::PickupDestination do
  subject(:pickup_destination) do
    described_class.new(
      'GREEN'
    )
  end

  before do
    allow(Settings).to receive(:libraries).and_return(
      {
        'GREEN' => double(Config::Options, label: 'Green Library')
      }
    )
  end

  describe '#display_label' do
    it 'returns library label' do
      expect(subject.display_label).to eq 'Green Library'
    end
  end

  describe '#paging_code' do
    it 'returns the library code' do
      expect(subject.paging_code).to eq 'GREEN'
    end
  end
end
