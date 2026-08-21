# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::Activity do
  let(:now) { Time.zone.now }

  describe '#in_progress?' do
    it 'is true when now falls between the start and the stop' do
      activity = build(:aeon_activity, start_time: now - 1.day, stop_time: now + 1.day)

      expect(activity).to be_in_progress
    end

    it 'is false before the start' do
      activity = build(:aeon_activity, start_time: now + 1.hour, stop_time: now + 2.hours)

      expect(activity).not_to be_in_progress
    end

    it 'is false after the stop' do
      activity = build(:aeon_activity, start_time: now - 2.days, stop_time: now - 1.day)

      expect(activity).not_to be_in_progress
    end

    it 'is false without a stop_time' do
      activity = build(:aeon_activity, start_time: now - 1.day, stop_time: nil)

      expect(activity).not_to be_in_progress
    end

    it 'is false without a start_time' do
      activity = build(:aeon_activity, start_time: nil, stop_time: now + 1.day)

      expect(activity).not_to be_in_progress
    end
  end
end
