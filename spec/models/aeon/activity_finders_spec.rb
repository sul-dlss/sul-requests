# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::ActivityFinders do
  let(:now) { Time.zone.now }

  let(:active_class_visit) { build(:aeon_activity, id: 1, active: true, status: 'Pending') }
  let(:completed_activity) { build(:aeon_activity, id: 2, active: true, status: 'Completed') }
  let(:inactive_activity) { build(:aeon_activity, id: 3, active: false, status: 'Pending') }

  describe '#active' do
    it 'returns only activities where active? is true' do
      finders = described_class.new([active_class_visit, completed_activity, inactive_activity])

      expect(finders.active.map(&:id)).to eq [1]
    end

    it 'returns an ActivityFinders instance' do
      finders = described_class.new([active_class_visit])

      expect(finders.active).to be_a(described_class)
    end
  end

  describe '#past' do
    it 'returns activities where active? is false' do
      finders = described_class.new([active_class_visit, completed_activity, inactive_activity])

      expect(finders.past.map(&:id)).to contain_exactly(2, 3)
    end

    it 'returns an ActivityFinders instance' do
      finders = described_class.new([inactive_activity])

      expect(finders.past).to be_a(described_class)
    end
  end

  describe '#find' do
    let(:finders) { described_class.new([active_class_visit, completed_activity, inactive_activity]) }

    it 'returns a single activity when given an id' do
      expect(finders.find(2)).to eq completed_activity
    end

    it 'coerces string ids' do
      expect(finders.find('2')).to eq completed_activity
    end

    it 'returns a new ActivityFinders when given an array of ids' do
      result = finders.find([1, 3])

      expect(result).to be_a(described_class)
      expect(result.map(&:id)).to contain_exactly(1, 3)
    end

    it 'falls back to Enumerable#find when a block is given' do
      result = finders.find { |a| a.status == 'Completed' }

      expect(result).to eq completed_activity
    end
  end

  describe '#upcoming (via ScheduledFinders)' do
    let(:past) { build(:aeon_activity, id: 10, start_time: now - 1.day) }
    let(:soon) { build(:aeon_activity, id: 11, start_time: now + 2.hours) }
    let(:tomorrow) { build(:aeon_activity, id: 12, start_time: now + 1.day) }
    let(:far_future) { build(:aeon_activity, id: 13, start_time: now + 30.days) }
    let(:no_start) { build(:aeon_activity, id: 14, start_time: nil) }

    it 'returns future activities within the window sorted by start_time' do
      finders = described_class.new([tomorrow, past, soon, far_future, no_start])

      expect(finders.upcoming(within: 7.days, fallback: 1).map(&:id)).to eq [11, 12]
    end

    it 'excludes activities without a start_time' do
      finders = described_class.new([no_start, soon])

      expect(finders.upcoming(within: 7.days, fallback: 1).map(&:id)).to eq [11]
    end

    it 'falls back to the next N upcoming activities when nothing is in the window' do
      finders = described_class.new([past, far_future, no_start])

      expect(finders.upcoming(within: 7.days, fallback: 1).map(&:id)).to eq [13]
    end

    it 'returns an empty result when there are no future activities' do
      finders = described_class.new([past, no_start])

      expect(finders.upcoming(within: 7.days, fallback: 1)).to be_empty
    end
  end
end
