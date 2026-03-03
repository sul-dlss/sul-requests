# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::RequestGrouping do
  describe '.from_requests' do
    let(:reading_room_a) { build(:aeon_request, title: 'Title A', transaction_number: 1) }
    let(:reading_room_a2) { build(:aeon_request, title: 'Title A', transaction_number: 2) }
    let(:reading_room_b) { build(:aeon_request, title: 'Title B', transaction_number: 3) }
    let(:digital_a) { build(:aeon_request, :digitized, title: 'Title A', transaction_number: 4) }

    it 'groups requests by title and request type' do
      groups = described_class.from_requests([reading_room_a, reading_room_a2, reading_room_b, digital_a])

      expect(groups.count).to eq(3)
    end

    it 'groups same-title reading room requests together' do
      groups = described_class.from_requests([reading_room_a, reading_room_a2, reading_room_b])
      title_a_group = groups.find { |g| g.title == 'Title A' }

      expect(title_a_group.count).to eq(2)
      expect(title_a_group.requests).to contain_exactly(reading_room_a, reading_room_a2)
    end

    it 'keeps digitization and reading room requests with the same title separate' do
      groups = described_class.from_requests([reading_room_a, digital_a])

      expect(groups.count).to eq(2)
      expect(groups.map(&:digital?)).to contain_exactly(true, false)
    end
  end
end
