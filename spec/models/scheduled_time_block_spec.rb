# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ScheduledTimeBlock do
  let(:start_time) { Time.zone.parse('2026-05-12T14:00:00Z') }
  let(:stop_time) { Time.zone.parse('2026-05-12T16:00:00Z') }

  describe '#renderable?' do
    it 'is true when start_time is present' do
      block = described_class.new(start_time:, stop_time:, location: 'Reading Room', day_only: false)
      expect(block).to be_renderable
    end

    it 'is false when start_time is nil' do
      block = described_class.new(start_time: nil, stop_time:, location: 'Reading Room', day_only: false)
      expect(block).not_to be_renderable
    end
  end

  describe '#date_only?' do
    it 'mirrors day_only' do
      expect(described_class.new(start_time:, stop_time:, location: nil, day_only: true)).to be_date_only
      expect(described_class.new(start_time:, stop_time:, location: nil, day_only: false)).not_to be_date_only
    end
  end

  describe '#time_of_day?' do
    it 'is true when both times are present and day_only is false' do
      block = described_class.new(start_time:, stop_time:, location: nil, day_only: false)
      expect(block).to be_time_of_day
    end

    it 'is false when day_only is true' do
      block = described_class.new(start_time:, stop_time:, location: nil, day_only: true)
      expect(block).not_to be_time_of_day
    end

    it 'is false when stop_time is missing' do
      block = described_class.new(start_time:, stop_time: nil, location: nil, day_only: false)
      expect(block).not_to be_time_of_day
    end
  end
end
