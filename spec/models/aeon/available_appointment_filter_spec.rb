# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::AvailableAppointmentFilter do
  subject(:filtered) { described_class.new(available_appointments: available_slots, existing_appointments:).filter }

  let(:date) { Time.zone.parse('2026-03-30T16:00:00Z') }

  def slot(hour, minute, max_minutes)
    Aeon::AvailableAppointment.new(
      start_time: date.change(hour:, min: minute),
      maximum_appointment_length: max_minutes.minutes
    )
  end

  def appointment(start, stop)
    build(:aeon_appointment,
          start_time: date.change(hour: start[0], min: start[1]),
          stop_time: date.change(hour: stop[0], min: stop[1]))
  end

  context 'with no existing appointments' do
    let(:existing_appointments) { [] }
    let(:available_slots) { [slot(9, 0, 180), slot(10, 0, 180)] }

    it 'returns all slots unchanged' do
      expect(filtered).to eq(available_slots)
    end
  end

  context 'when an existing appointment covers the slot start time' do
    let(:existing_appointments) { [appointment([9, 0], [11, 0])] }
    let(:available_slots) { [slot(9, 0, 180), slot(10, 0, 180), slot(11, 0, 180)] }

    it 'removes slots whose start time falls within the existing appointment' do
      expect(filtered.map(&:start_time)).to eq([date.change(hour: 11, min: 0)])
    end
  end

  context 'when an existing appointment starts during a slot range' do
    let(:existing_appointments) { [appointment([11, 0], [12, 0])] }
    let(:available_slots) { [slot(9, 0, 180), slot(10, 30, 180)] }

    it 'reduces maximum_appointment_length so the new appointment ends before the existing one starts' do
      expect(filtered.map { |s| [s.start_time.strftime('%H:%M'), s.maximum_appointment_length] }).to eq([
                                                                                                          ['09:00', 120.minutes],
                                                                                                          ['10:30', 30.minutes]
                                                                                                        ])
    end
  end

  context 'when reduced max length falls below the minimum (30 minutes)' do
    let(:existing_appointments) { [appointment([10, 15], [11, 0])] }
    let(:available_slots) { [slot(10, 0, 180)] }

    it 'removes the slot when the gap is less than the minimum appointment length' do
      expect(filtered).to be_empty
    end

    context 'when the gap is exactly 30 minutes' do
      let(:existing_appointments) { [appointment([10, 30], [11, 0])] }

      it 'keeps the slot with reduced max length' do
        expect(filtered.length).to eq(1)
        expect(filtered.first.maximum_appointment_length).to eq(30.minutes)
      end
    end
  end

  context 'with multiple existing appointments' do
    let(:existing_appointments) { [appointment([10, 0], [11, 0]), appointment([14, 0], [15, 0])] }
    let(:available_slots) do
      [slot(9, 0, 180), slot(10, 0, 180), slot(12, 0, 180), slot(15, 0, 180)]
    end

    it 'filters considering all existing appointments' do
      expect(filtered.map { |s| [s.start_time.strftime('%H:%M'), s.maximum_appointment_length] }).to eq([
                                                                                                          ['09:00', 60.minutes],
                                                                                                          ['12:00', 120.minutes],
                                                                                                          ['15:00', 180.minutes]
                                                                                                        ])
    end
  end

  context 'with no overlap' do
    let(:existing_appointments) { [appointment([6, 0], [8, 0])] }
    let(:available_slots) { [slot(9, 0, 180), slot(10, 0, 180)] }

    it 'returns all slots unchanged' do
      expect(filtered).to eq(available_slots)
    end
  end
end
