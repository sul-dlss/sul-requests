# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::Activity do
  let(:start_time) { Time.zone.parse('2026-05-12T14:00:00Z') }
  let(:stop_time) { Time.zone.parse('2026-05-12T16:00:00Z') }

  describe '.from_dynamic' do
    let(:data) do
      {
        'id' => 7,
        'beginDate' => '2026-05-12T14:00:00Z',
        'endDate' => '2026-05-12T16:00:00Z',
        'name' => 'Class visit',
        'active' => true,
        'location' => 'Special Collections',
        'activityType' => 'Class visit',
        'activityStatus' => 'Open',
        'users' => []
      }
    end

    it 'parses the activity fields' do
      activity = described_class.from_dynamic(data)
      expect(activity).to have_attributes(
        id: 7,
        name: 'Class visit',
        location: 'Special Collections',
        activity_type: 'Class visit',
        sites: ['SPECUA']
      )
    end
  end

  describe '#scheduled_time_block' do
    it 'wraps the activity time and location with day_only false' do
      activity = described_class.new(start_time:, stop_time:, location: 'Special Collections')
      expect(activity.scheduled_time_block).to have_attributes(
        start_time:,
        stop_time:,
        location: 'Special Collections',
        day_only: false
      )
    end

    it 'returns nil when start_time is missing' do
      activity = described_class.new(start_time: nil, stop_time:, location: 'Special Collections')
      expect(activity.scheduled_time_block).to be_nil
    end

    it 'returns nil when location is missing' do
      activity = described_class.new(start_time:, stop_time:, location: nil)
      expect(activity.scheduled_time_block).to be_nil
    end
  end
end
