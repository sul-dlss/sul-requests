# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::AppointmentSlotAvailability do
  let(:reading_room) { instance_double(Aeon::ReadingRoom) }
  let(:user_appointments) { instance_double(Aeon::AppointmentFinders) }
  let(:user) { instance_double(Aeon::User, appointments: user_appointments) }
  let(:availability) { described_class.new(reading_room: reading_room, user: user) }

  def slot(start_at, max_minutes)
    Aeon::AvailableAppointment.new(start_time: Time.zone.parse(start_at), maximum_appointment_length: max_minutes.minutes)
  end

  before do
    allow(user_appointments).to receive(:for_reading_room).with(reading_room).and_return([])
  end

  describe '#slots_on' do
    let(:date) { Date.parse('2026-06-15') }

    it 'delegates the raw available slots fetch to the reading room' do
      allow(reading_room).to receive(:available_appointments).with(date, include_next_available: false).and_return([])
      availability.slots_on(date)
      expect(reading_room).to have_received(:available_appointments).with(date, include_next_available: false)
    end

    it 'passes include_next_available through to the reading room' do
      allow(reading_room).to receive(:available_appointments).with(date, include_next_available: true).and_return([])
      availability.slots_on(date, include_next_available: true)
      expect(reading_room).to have_received(:available_appointments).with(date, include_next_available: true)
    end

    it "returns the reading room's slots when the user has no existing appointments" do
      one_slot = slot('2026-06-15 10:00', 120)
      allow(reading_room).to receive(:available_appointments).and_return([one_slot])
      expect(availability.slots_on(date)).to eq([one_slot])
    end

    it "excludes the user's existing appointments from the deconfliction set when excluding_id matches" do
      excluded = build(:aeon_appointment, id: 42, start_time: Time.zone.parse('2026-06-15 10:00'),
                                          stop_time: Time.zone.parse('2026-06-15 11:00'))
      allow(user_appointments).to receive(:for_reading_room).with(reading_room).and_return([excluded])
      one_slot = slot('2026-06-15 10:00', 120)
      allow(reading_room).to receive(:available_appointments).and_return([one_slot])

      expect(availability.slots_on(date, excluding_id: 42)).to eq([one_slot])
    end

    it 'deconflicts against the users other existing appointments' do
      conflicting = build(:aeon_appointment, id: 99, start_time: Time.zone.parse('2026-06-15 10:00'),
                                             stop_time: Time.zone.parse('2026-06-15 11:00'))
      allow(user_appointments).to receive(:for_reading_room).with(reading_room).and_return([conflicting])
      allow(reading_room).to receive(:available_appointments).and_return([slot('2026-06-15 10:00', 120)])

      expect(availability.slots_on(date)).to be_empty
    end
  end

  describe '#available_at?' do
    let(:range) { Time.zone.parse('2026-06-15 10:00')..Time.zone.parse('2026-06-15 11:00') }

    it 'is true when a slot starts at the range start and covers the requested duration' do
      allow(reading_room).to receive(:available_appointments).and_return([slot('2026-06-15 10:00', 120)])
      expect(availability.available_at?(range: range)).to be true
    end

    it 'is false when the slot starts at a different time' do
      allow(reading_room).to receive(:available_appointments).and_return([slot('2026-06-15 10:15', 120)])
      expect(availability.available_at?(range: range)).to be false
    end

    it 'is false when the slot is shorter than the requested duration' do
      allow(reading_room).to receive(:available_appointments).and_return([slot('2026-06-15 10:00', 30)])
      expect(availability.available_at?(range: range)).to be false
    end

    it 'is false when the reading room has no availability' do
      allow(reading_room).to receive(:available_appointments).and_return([])
      expect(availability.available_at?(range: range)).to be false
    end

    it 'ignores an existing appointment matching excluding_id' do
      excluded = build(:aeon_appointment, id: 7, start_time: range.begin, stop_time: range.end)
      allow(user_appointments).to receive(:for_reading_room).with(reading_room).and_return([excluded])
      allow(reading_room).to receive(:available_appointments).and_return([slot('2026-06-15 10:00', 120)])
      expect(availability.available_at?(range: range, excluding_id: 7)).to be true
    end
  end
end
