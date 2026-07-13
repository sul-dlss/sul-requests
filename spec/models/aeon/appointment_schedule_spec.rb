# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::AppointmentSchedule do
  subject(:schedule) { described_class.new(reading_room: reading_room) }

  let(:reading_room) { nil }

  describe '#min' do
    context 'when no reading room is present' do
      it 'is today' do
        expect(schedule.min).to eq(Time.zone.today.iso8601)
      end
    end

    context 'with a reading room that has a next appointment' do
      let(:reading_room) do
        build(:aeon_reading_room).tap do |rr|
          rr.instance_variable_set(:@next_appointment, instance_double(Aeon::Appointment, start_time: 2.weeks.from_now))
        end
      end

      it 'uses the next appointment date' do
        expect(schedule.min).to eq(2.weeks.from_now.to_date.iso8601)
      end
    end

    context 'with an explicit override' do
      subject(:schedule) { described_class.new(reading_room: nil, min: '2026-08-01') }

      it 'uses the override' do
        expect(schedule.min).to eq('2026-08-01')
      end
    end
  end

  describe '#open_days' do
    context 'with a reading room' do
      let(:reading_room) do
        build(:aeon_reading_room,
              open_hours: [build(:aeon_reading_room_open_hours, day_name: 'Monday'),
                           build(:aeon_reading_room_open_hours, day_name: 'Wednesday')])
      end

      it 'returns the reading room open days' do
        expect(schedule.open_days).to eq(%w[Monday Wednesday])
      end
    end

    context 'without a reading room' do
      it 'returns all days' do
        expect(schedule.open_days).to eq(Date::DAYNAMES)
      end
    end
  end

  describe '#disabled_dates' do
    let(:reading_room) { build(:aeon_reading_room) }

    before do
      allow(reading_room).to receive(:fully_closed_dates).and_return([Date.parse('2026-06-01')])
    end

    it 'includes the reading room closures' do
      expect(schedule.disabled_dates).to eq(['2026-06-01'])
    end

    context 'with day-only appointments and existing appointments' do
      subject(:schedule) { described_class.new(reading_room: reading_room, existing_appointments: ['2026-06-10']) }

      before { allow(reading_room).to receive(:day_only_appointments?).and_return(true) }

      it 'adds existing appointment dates to the disabled list' do
        expect(schedule.disabled_dates).to contain_exactly('2026-06-01', '2026-06-10')
      end
    end

    context 'without day-only appointments' do
      subject(:schedule) { described_class.new(reading_room: reading_room, existing_appointments: ['2026-06-10']) }

      before { allow(reading_room).to receive(:day_only_appointments?).and_return(false) }

      it 'ignores existing appointment dates' do
        expect(schedule.disabled_dates).to eq(['2026-06-01'])
      end
    end
  end

  describe '#availability_url' do
    context 'when Aeon availability is disabled' do
      let(:reading_room) { build(:aeon_reading_room, id: 5) }

      before { allow(Settings.aeon).to receive(:date_picker_availability_enabled).and_return(false) }

      it 'returns nil' do
        expect(schedule.availability_url).to be_nil
      end
    end

    context 'when Aeon availability is enabled' do
      subject(:schedule) { described_class.new(reading_room: reading_room, appointment_id: 42) }

      let(:reading_room) { build(:aeon_reading_room, id: 5) }

      before { allow(Settings.aeon).to receive(:date_picker_availability_enabled).and_return(true) }

      it 'points at the reading-room unavailable-dates endpoint' do
        expect(schedule.availability_url).to eq('/aeon_reading_rooms/5/unavailable_dates?appointment_id=42')
      end
    end
  end
end
