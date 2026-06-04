# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::Appointment do
  let(:data) do
    {
      'id' => 26,
      'username' => 'nerdsquirrel@stanford.edu',
      'readingRoomID' => 5,
      'startTime' => '2026-01-23T17:00:00Z',
      'stopTime' => '2026-01-23T23:00:00Z',
      'name' => 'Nerd Squirrel',
      'availableToProxies' => true,
      'appointmentStatus' => 'Unconfirmed',
      'creationDate' => '2026-01-15T08:41:50.113Z',
      'readingRoom' => {
        'id' => 5,
        'name' => 'Field Reading Room',
        'availableSeats' => 15,
        'timeZoneID' => 'Pacific Standard Time',
        'minAppointmentLength' => 30,
        'maxAppointmentLength' => 480,
        'appointmentPadding' => 0,
        'appointmentIncrement' => 15,
        'lastModifiedTime' => '2022-09-01T16:13:22.477Z',
        'sites' => ['SPECUA'],
        'openHours' => [
          { 'dayOfWeek' => 1, 'dayName' => 'Monday', 'openTime' => '09:00:00', 'closeTime' => '16:45:00' }
        ],
        'policies' => [
          { 'id' => 4, 'readingRoomID' => 5, 'appointmentRequired' => true }
        ]
      }
    }
  end

  describe '.from_dynamic' do
    subject(:appointment) { described_class.from_dynamic(data) }

    it 'parses the appointment fields' do
      expect(appointment).to have_attributes(
        id: 26,
        username: 'nerdsquirrel@stanford.edu',
        name: 'Nerd Squirrel',
        appointment_status: 'Unconfirmed'
      )
    end

    it 'parses the nested reading room' do
      expect(appointment.reading_room).to have_attributes(
        id: 5,
        name: 'Field Reading Room',
        sites: ['SPECUA']
      )
    end

    it 'parses reading room open hours' do
      hours = appointment.reading_room.open_hours
      expect(hours.first).to have_attributes(day_name: 'Monday', open_time: an_object_having_attributes(hour: 9, min: 0))
    end

    it 'parses reading room policies' do
      policies = appointment.reading_room.policies
      expect(policies.first).to have_attributes(id: 4, reading_room_id: 5)
    end
  end

  describe '#available_to_proxies?' do
    it 'returns true when available_to_proxies' do
      appointment = build(:aeon_appointment, available_to_proxies: true)
      expect(appointment).to be_available_to_proxies
    end

    it 'returns false when not available_to_proxies' do
      appointment = build(:aeon_appointment, available_to_proxies: false)
      expect(appointment).not_to be_available_to_proxies
    end
  end

  describe 'validations' do
    let(:reading_room) { build(:aeon_reading_room) }
    let(:appointment) do
      build(:aeon_appointment, reading_room: reading_room, start_time: start_time, stop_time: stop_time)
    end

    before do
      allow(reading_room).to receive(:closures).and_return([])
    end

    context 'with a start_time and stop_time inside open hours' do
      # Monday 10:00-11:00 PT (reading room is open Mon 9:00-16:45)
      let(:start_time) { Time.zone.parse('2026-03-16T10:00:00-07:00') }
      let(:stop_time)  { Time.zone.parse('2026-03-16T11:00:00-07:00') }

      it { expect(appointment).to be_valid }
    end

    context 'when start_time falls on a day the reading room is closed' do
      let(:start_time) { Time.zone.parse('2026-03-14T10:00:00-07:00') }
      let(:stop_time)  { Time.zone.parse('2026-03-14T11:00:00-07:00') }

      it { expect(appointment).not_to be_valid }
    end

    context 'when start_time is before opening' do
      # Monday 08:30 PT, opens at 09:00
      let(:start_time) { Time.zone.parse('2026-03-16T08:30:00-07:00') }
      let(:stop_time)  { Time.zone.parse('2026-03-16T10:00:00-07:00') }

      it { expect(appointment).not_to be_valid }
    end

    context 'when stop_time is after closing' do
      # Monday 16:00-17:30 PT, closes at 16:45
      let(:start_time) { Time.zone.parse('2026-03-16T16:00:00-07:00') }
      let(:stop_time)  { Time.zone.parse('2026-03-16T17:30:00-07:00') }

      it { expect(appointment).not_to be_valid }
    end

    context 'when stop_time is not after start_time' do
      let(:start_time) { Time.zone.parse('2026-03-16T10:00:00-07:00') }
      let(:stop_time)  { Time.zone.parse('2026-03-16T10:00:00-07:00') }

      it { expect(appointment).not_to be_valid }
    end

    describe '#save' do
      let(:appointment) do
        build(:aeon_appointment, id: nil, reading_room: reading_room, start_time: start_time, stop_time: stop_time)
      end
      let(:start_time) { Time.zone.parse('2026-03-16T10:00:00-07:00') }
      let(:stop_time)  { Time.zone.parse('2026-03-16T11:00:00-07:00') }

      context 'when invalid' do
        let(:start_time) { Time.zone.parse('2026-03-16T08:00:00-07:00') } # before opening
        let(:client) { instance_double(AeonClient) }

        before do
          allow(Current).to receive(:aeon_client).and_return(client)
          allow(client).to receive(:create_appointment)
        end

        it 'returns false and does not call the Aeon client' do
          expect(appointment.save).to be false
          expect(client).not_to have_received(:create_appointment)
        end
      end

      context 'when valid' do
        let(:client) { instance_double(AeonClient) }
        let(:saved) do
          build(:aeon_appointment, id: 999, appointment_status: 'Confirmed',
                                   creation_date: Time.zone.parse('2026-03-15T00:00:00Z'),
                                   available_to_proxies: true)
        end

        before do
          allow(Current).to receive(:aeon_client).and_return(client)
          allow(client).to receive(:create_appointment).and_return(saved)
        end

        it 'persists and copies returned attributes onto self' do
          expect(appointment.save).to be true
          expect(appointment).to have_attributes(id: 999, appointment_status: 'Confirmed', available_to_proxies: true)
        end
      end
    end

    context 'with closures' do
      before do
        closure = Aeon::ReadingRoomClosures.new(
          start_date: Time.zone.parse('2026-03-16T14:00:00-07:00'),
          end_date: Time.zone.parse('2026-03-16T15:00:00-07:00')
        )
        allow(reading_room).to receive(:closures).and_return([closure])
      end

      context 'when start_time falls within a closure' do
        # Appointment starts inside the 14:00-15:00 closure
        let(:start_time) { Time.zone.parse('2026-03-16T14:30:00-07:00') }
        let(:stop_time)  { Time.zone.parse('2026-03-16T15:30:00-07:00') }

        it { expect(appointment).not_to be_valid }
      end

      context 'when stop_time falls within a closure' do
        # Appointment ends inside the 14:00-15:00 closure
        let(:start_time) { Time.zone.parse('2026-03-16T13:30:00-07:00') }
        let(:stop_time)  { Time.zone.parse('2026-03-16T14:30:00-07:00') }

        it { expect(appointment).not_to be_valid }
      end

      context 'when appointment straddles a closure' do
        # Appointment starts before and ends after the 14:00-15:00 closure
        let(:start_time) { Time.zone.parse('2026-03-16T13:30:00-07:00') }
        let(:stop_time)  { Time.zone.parse('2026-03-16T15:30:00-07:00') }

        it { expect(appointment).not_to be_valid }
      end
    end
  end
end
