# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::Activity do
  let(:now) { Time.zone.now }

  describe '#requests' do
    let(:activity) { build(:aeon_activity, id: 7, users: [user]) }
    let(:user) { instance_double(Aeon::User, own_requests: Aeon::RequestFinders.new(all_requests)) }
    let(:all_requests) { [submitted, completed, cancelled, other_activity] }
    let(:submitted) { build(:aeon_request, :submitted, :without_appointment, transaction_number: 1, activity_id: 7) }
    let(:completed) { build(:aeon_request, :delivered, :without_appointment, transaction_number: 2, activity_id: 7) }
    let(:cancelled) do
      build(:aeon_request, :cancelled_by_staff, :without_appointment, transaction_number: 3, activity_id: 7)
    end
    let(:other_activity) { build(:aeon_request, :submitted, :without_appointment, transaction_number: 5, activity_id: 8) }

    it 'keeps completed requests so past activities still list their items' do
      expect(activity.requests.map(&:transaction_number)).to include 2
    end

    it 'only includes requests for this activity' do
      expect(activity.requests.map(&:transaction_number)).to contain_exactly(1, 2)
    end
  end

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
