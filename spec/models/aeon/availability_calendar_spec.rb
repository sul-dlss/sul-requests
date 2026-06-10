# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::AvailabilityCalendar do
  subject(:calendar) { described_class.new(reading_room:, user_appointments:) }

  # Monday 2026-06-15, reading room is open 9:00-16:45 PT (7h 45m)
  let(:reading_room) { build(:aeon_reading_room) }
  let(:user_appointments) { [] }
  let(:date) { Date.parse('2026-06-15') }

  before { allow(reading_room).to receive(:closures).and_return([]) }

  describe '#no_room?' do
    context 'with no conflicts or closures' do
      it { expect(calendar.no_room?(date)).to be false }
    end

    context 'when the room is not open on the date' do
      # Sunday, no open hours
      let(:date) { Date.parse('2026-06-14') }

      it { expect(calendar.no_room?(date)).to be false }
    end

    context 'when a single appointment covers the entire open range' do
      let(:user_appointments) do
        [build(:aeon_appointment, reading_room: reading_room,
                                  start_time: Time.zone.parse('2026-06-15T09:00:00-07:00'),
                                  stop_time: Time.zone.parse('2026-06-15T16:45:00-07:00'))]
      end

      it { expect(calendar.no_room?(date)).to be true }
    end

    context 'when conflicts leave a gap shorter than the minimum length' do
      # min_appointment_length is 30 minutes. Leave only a 15-minute window.
      let(:user_appointments) do
        [
          build(:aeon_appointment, reading_room: reading_room,
                                   start_time: Time.zone.parse('2026-06-15T09:00:00-07:00'),
                                   stop_time: Time.zone.parse('2026-06-15T09:15:00-07:00')),
          build(:aeon_appointment, reading_room: reading_room,
                                   start_time: Time.zone.parse('2026-06-15T09:30:00-07:00'),
                                   stop_time: Time.zone.parse('2026-06-15T16:45:00-07:00'))
        ]
      end

      it { expect(calendar.no_room?(date)).to be true }
    end

    context 'when conflicts leave a gap at least as long as the minimum length' do
      # Leave exactly 30 minutes in the middle.
      let(:user_appointments) do
        [
          build(:aeon_appointment, reading_room: reading_room,
                                   start_time: Time.zone.parse('2026-06-15T09:00:00-07:00'),
                                   stop_time: Time.zone.parse('2026-06-15T12:00:00-07:00')),
          build(:aeon_appointment, reading_room: reading_room,
                                   start_time: Time.zone.parse('2026-06-15T12:30:00-07:00'),
                                   stop_time: Time.zone.parse('2026-06-15T16:45:00-07:00'))
        ]
      end

      it { expect(calendar.no_room?(date)).to be false }
    end

    context 'when conflicts overlap each other' do
      # Two overlapping conflicts should be merged before measuring gaps.
      let(:user_appointments) do
        [
          build(:aeon_appointment, reading_room: reading_room,
                                   start_time: Time.zone.parse('2026-06-15T09:00:00-07:00'),
                                   stop_time: Time.zone.parse('2026-06-15T13:00:00-07:00')),
          build(:aeon_appointment, reading_room: reading_room,
                                   start_time: Time.zone.parse('2026-06-15T12:00:00-07:00'),
                                   stop_time: Time.zone.parse('2026-06-15T16:45:00-07:00'))
        ]
      end

      it { expect(calendar.no_room?(date)).to be true }
    end

    context 'when conflicts fall outside the open range' do
      # Conflicts at 7-8 AM and 6-7 PM, fully outside the 9:00-16:45 window.
      let(:user_appointments) do
        [
          build(:aeon_appointment, reading_room: reading_room,
                                   start_time: Time.zone.parse('2026-06-15T07:00:00-07:00'),
                                   stop_time: Time.zone.parse('2026-06-15T08:00:00-07:00')),
          build(:aeon_appointment, reading_room: reading_room,
                                   start_time: Time.zone.parse('2026-06-15T18:00:00-07:00'),
                                   stop_time: Time.zone.parse('2026-06-15T19:00:00-07:00'))
        ]
      end

      it { expect(calendar.no_room?(date)).to be false }
    end

    context 'when a partial closure leaves no room' do
      let(:closure) do
        Aeon::ReadingRoomClosures.new(
          start_date: Time.zone.parse('2026-06-15T09:00:00-07:00'),
          end_date: Time.zone.parse('2026-06-15T16:30:00-07:00')
        )
      end

      before { allow(reading_room).to receive(:closures).and_return([closure]) }

      it 'considers the closure when measuring gaps' do
        expect(calendar.no_room?(date)).to be true
      end
    end
  end

  describe '#dates_with_no_room' do
    let(:date_range) { Date.parse('2026-06-15')..Date.parse('2026-06-19') }
    let(:user_appointments) do
      # Block 6/15 (Mon) entirely; leave 6/16 (Tue) open
      [build(:aeon_appointment, reading_room: reading_room,
                                start_time: Time.zone.parse('2026-06-15T09:00:00-07:00'),
                                stop_time: Time.zone.parse('2026-06-15T16:45:00-07:00'))]
    end

    it 'returns only the dates that have no room' do
      expect(calendar.dates_with_no_room(date_range)).to eq [Date.parse('2026-06-15')]
    end

    context 'with no reading room' do
      let(:reading_room) { nil }

      it 'returns an empty list' do
        expect(calendar.dates_with_no_room(date_range)).to eq []
      end
    end

    context 'with a closure that spans dates outside the range' do
      let(:date_range) { Date.parse('2026-06-15')..Date.parse('2026-06-22') }
      let(:user_appointments) { [] }
      let(:closure) do
        Aeon::ReadingRoomClosures.new(
          start_date: Time.zone.parse('2026-06-22T09:00:00-07:00'),
          end_date: Time.zone.parse('2026-06-29T16:45:00-07:00')
        )
      end

      before { allow(reading_room).to receive(:closures).and_return([closure]) }

      it 'only returns closure dates within the range' do
        expect(calendar.dates_with_no_room(date_range)).to eq [Date.parse('2026-06-22')]
      end
    end

    context 'with an appointment on a date outside the range' do
      let(:date_range) { Date.parse('2026-06-15')..Date.parse('2026-06-15') }
      let(:user_appointments) do
        [build(:aeon_appointment, reading_room: reading_room,
                                  start_time: Time.zone.parse('2026-06-22T09:00:00-07:00'),
                                  stop_time: Time.zone.parse('2026-06-22T16:45:00-07:00'))]
      end

      it 'ignores it' do
        expect(calendar.dates_with_no_room(date_range)).to eq []
      end
    end
  end
end
