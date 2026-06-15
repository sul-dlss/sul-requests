# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::AppointmentDeconflictionService do
  def available(start_at, max_minutes)
    Aeon::AvailableAppointment.new(start_time: Time.zone.parse(start_at), maximum_appointment_length: max_minutes.minutes)
  end

  def existing(start_at, stop_at)
    build(:aeon_appointment, start_time: Time.zone.parse(start_at), stop_time: Time.zone.parse(stop_at))
  end

  def call(available_appointments, existing_appointments)
    described_class.new(available_appointments: Array(available_appointments), existing_appointments: Array(existing_appointments)).call
  end

  describe 'no conflict' do
    it 'returns available appointment unaltered' do
      slot = available('2026-06-15 10:00', 120)
      existing_appointments = [existing('2026-06-15 13:00', '2026-06-15 14:00')]
      result = call(slot, existing_appointments)
      expect(result.size).to eq(1)
      expect(result.first.maximum_appointment_length).to eq(120.minutes)
    end
  end

  describe 'wholly conflicted (existing covers start)' do
    it 'discards the available' do
      slot = available('2026-06-15 10:00', 120)
      existing_appointments = [existing('2026-06-15 09:30', '2026-06-15 10:30')]
      expect(call(slot, existing_appointments)).to be_empty
    end

    it 'discards when existing starts at exact same time' do
      slot = available('2026-06-15 10:00', 120)
      existing_appointments = [existing('2026-06-15 10:00', '2026-06-15 11:00')]
      expect(call(slot, existing_appointments)).to be_empty
    end
  end

  describe 'conflict within slot' do
    it 'truncates to earliest conflict' do
      slot = available('2026-06-15 10:00', 240)
      existing_appointments = [existing('2026-06-15 11:30', '2026-06-15 12:30')]
      result = call(slot, existing_appointments)
      expect(result.first.maximum_appointment_length).to eq(90.minutes)
    end

    it 'truncates to earliest of multiple conflicts' do
      slot = available('2026-06-15 10:00', 240)
      existing_appointments = [
        existing('2026-06-15 12:00', '2026-06-15 12:30'),
        existing('2026-06-15 11:00', '2026-06-15 11:15')
      ]
      result = call(slot, existing_appointments)
      expect(result.first.maximum_appointment_length).to eq(60.minutes)
    end
  end

  describe 'existing starts after slot stop_time' do
    it 'returns slot unaltered' do
      slot = available('2026-06-15 10:00', 120)
      existing_appointments = [existing('2026-06-15 13:00', '2026-06-15 14:00')]
      result = call(slot, existing_appointments)
      expect(result.first.maximum_appointment_length).to eq(120.minutes)
    end
  end

  describe 'existing fully bracketed by an earlier and later available slot' do
    it 'truncates the earlier slot and leaves the later slot unaltered' do
      early = available('2026-06-15 10:00', 240)
      late = available('2026-06-15 14:00', 240)
      existing_appointments = [existing('2026-06-15 12:00', '2026-06-15 13:00')]
      result = call([early, late], existing_appointments)
      expect(result.size).to eq(2)
      expect(result.first.maximum_appointment_length).to eq(120.minutes)
      expect(result.last.maximum_appointment_length).to eq(240.minutes)
    end
  end

  describe 'multiple available slots near same existing' do
    it 'shortens each slot relative to its own start_time' do
      slot_a = available('2026-06-15 10:00', 240)
      slot_b = available('2026-06-15 11:00', 240)
      existing_appointments = [existing('2026-06-15 12:30', '2026-06-15 13:00')]
      result = call([slot_a, slot_b], existing_appointments)
      expect(result[0].maximum_appointment_length).to eq(150.minutes)
      expect(result[1].maximum_appointment_length).to eq(90.minutes)
    end
  end

  describe 'existing whose start equals slot stop_time' do
    it 'leaves slot unaltered (existing starts right when slot ends)' do
      slot = available('2026-06-15 10:00', 120)
      existing_appointments = [existing('2026-06-15 12:00', '2026-06-15 13:00')]
      result = call(slot, existing_appointments)
      expect(result.first.maximum_appointment_length).to eq(120.minutes)
    end
  end
end
