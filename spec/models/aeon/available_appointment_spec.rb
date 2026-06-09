# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::AvailableAppointment do
  describe '.from_dynamic' do
    subject(:slot) do
      described_class.from_dynamic(
        'utcStartTime' => '2026-04-13T17:00:00Z',
        'maximumAppointmentLengthMinutes' => 240
      )
    end

    it 'parses the start time and converts the length to a duration' do
      expect(slot).to have_attributes(
        start_time: Time.zone.parse('2026-04-13T17:00:00Z'),
        maximum_appointment_length: 240.minutes
      )
    end
  end

  describe '#trimmed_for' do
    subject(:slot) do
      described_class.new(
        start_time: Time.zone.parse('2026-04-13T10:00:00-07:00'),
        maximum_appointment_length: 4.hours
      )
    end

    context 'when no conflicts are given' do
      it 'returns itself' do
        expect(slot.trimmed_for([])).to eq slot
      end
    end

    context 'when conflicts do not touch the slot window' do
      let(:conflict) do
        Time.zone.parse('2026-04-13T16:00:00-07:00')...Time.zone.parse('2026-04-13T17:00:00-07:00')
      end

      it 'returns itself' do
        expect(slot.trimmed_for([conflict])).to eq slot
      end
    end

    context 'when the slot start falls inside a conflict' do
      let(:conflict) do
        Time.zone.parse('2026-04-13T09:30:00-07:00')...Time.zone.parse('2026-04-13T10:30:00-07:00')
      end

      it 'returns nil' do
        expect(slot.trimmed_for([conflict])).to be_nil
      end
    end

    context 'when a conflict begins inside the slot window' do
      let(:conflict) do
        Time.zone.parse('2026-04-13T11:00:00-07:00')...Time.zone.parse('2026-04-13T12:00:00-07:00')
      end

      it 'trims the maximum length to end at the conflict start' do
        trimmed = slot.trimmed_for([conflict])
        expect(trimmed.start_time).to eq slot.start_time
        expect(trimmed.maximum_appointment_length).to eq 1.hour
      end
    end

    context 'when multiple conflicts begin inside the slot window' do
      let(:earlier) do
        Time.zone.parse('2026-04-13T11:00:00-07:00')...Time.zone.parse('2026-04-13T11:30:00-07:00')
      end
      let(:later) do
        Time.zone.parse('2026-04-13T13:00:00-07:00')...Time.zone.parse('2026-04-13T14:00:00-07:00')
      end

      it 'trims to the earliest conflict' do
        trimmed = slot.trimmed_for([later, earlier])
        expect(trimmed.maximum_appointment_length).to eq 1.hour
      end
    end

    context 'with a conflict ending exactly at the slot start (back-to-back)' do
      let(:conflict) do
        Time.zone.parse('2026-04-13T09:00:00-07:00')...Time.zone.parse('2026-04-13T10:00:00-07:00')
      end

      it 'returns itself' do
        expect(slot.trimmed_for([conflict])).to eq slot
      end
    end

    context 'with a conflict beginning exactly at the slot end' do
      let(:conflict) do
        Time.zone.parse('2026-04-13T14:00:00-07:00')...Time.zone.parse('2026-04-13T15:00:00-07:00')
      end

      it 'returns itself' do
        expect(slot.trimmed_for([conflict])).to eq slot
      end
    end
  end
end
