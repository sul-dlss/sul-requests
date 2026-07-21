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

  describe '#cancelled?' do
    it 'is true when appointment_status is Cancelled' do
      appointment = build(:aeon_appointment, appointment_status: 'Cancelled')
      expect(appointment).to be_cancelled
    end

    it 'is cancelled if the appointment is not editable and has no requests assigned' do
      appointment = build(:aeon_appointment, requests: [], start_time: 1.week.ago)

      expect(appointment).to be_cancelled
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

    context 'when a reading room has multiple open-hour blocks on the same day' do
      # ARS-style Thursday: 9:00-11:00 am and 12:00-3:00 pm
      let(:reading_room) do
        build(:aeon_reading_room, open_hours: [
                build(:aeon_reading_room_open_hours, day_of_week: 4, day_name: 'Thursday',
                                                     open_time: Time.zone.parse('09:00'), close_time: Time.zone.parse('11:00')),
                build(:aeon_reading_room_open_hours, day_of_week: 4, day_name: 'Thursday',
                                                     open_time: Time.zone.parse('12:00'), close_time: Time.zone.parse('15:00'))
              ])
      end

      context 'when the appointment falls in the afternoon block' do
        # Thursday 1:30 - 3:00 pm PT
        let(:start_time) { Time.zone.parse('2026-07-23T13:30:00-07:00') }
        let(:stop_time)  { Time.zone.parse('2026-07-23T15:00:00-07:00') }

        it { expect(appointment).to be_valid }
      end

      context 'when the appointment straddles the gap between the two blocks' do
        let(:start_time) { Time.zone.parse('2026-07-23T10:30:00-07:00') }
        let(:stop_time)  { Time.zone.parse('2026-07-23T12:30:00-07:00') }

        it { expect(appointment).not_to be_valid }
      end
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

      context 'when the Aeon client rejects the create' do
        let(:client) { instance_double(AeonClient) }

        before do
          allow(Current).to receive(:aeon_client).and_return(client)
          allow(client).to receive(:create_appointment).and_raise(AeonClient::ApiError.new('boom'))
          allow(Honeybadger).to receive(:notify)
        end

        it 'returns false, notifies Honeybadger, and adds a base error mentioning "created"' do
          expect(appointment.save).to be false
          expect(Honeybadger).to have_received(:notify).with(instance_of(AeonClient::ApiError))
          expect(appointment.errors[:base].first).to include('could not be created')
        end
      end

      context 'when the Aeon client rejects the update' do
        let(:appointment) do
          build(:aeon_appointment, id: 42, reading_room: reading_room, start_time: start_time, stop_time: stop_time)
        end
        let(:client) { instance_double(AeonClient) }

        before do
          allow(Current).to receive(:aeon_client).and_return(client)
          allow(client).to receive(:update_appointment).and_raise(AeonClient::ApiError.new('boom'))
          allow(Honeybadger).to receive(:notify)
        end

        it 'returns false and adds a base error mentioning "updated"' do
          expect(appointment.save).to be false
          expect(appointment.errors[:base].first).to include('could not be updated')
        end
      end

      context 'when persisted' do
        let(:appointment) do
          build(:aeon_appointment, id: 42, reading_room: reading_room, start_time: start_time, stop_time: stop_time)
        end
        let(:client) { instance_double(AeonClient) }

        before do
          allow(Current).to receive(:aeon_client).and_return(client)
          allow(client).to receive(:update_appointment)
          allow(client).to receive(:create_appointment)
        end

        it 'calls update_appointment and not create_appointment' do
          expect(appointment.save).to be true
          expect(client).to have_received(:update_appointment).with(42, name: nil, start_time: start_time, stop_time: stop_time)
          expect(client).not_to have_received(:create_appointment)
        end

        context 'when invalid' do
          let(:start_time) { Time.zone.parse('2026-03-16T08:00:00-07:00') } # before opening

          it 'returns false and does not call the Aeon client' do
            expect(appointment.save).to be false
            expect(client).not_to have_received(:update_appointment)
          end
        end
      end
    end

    context 'when a slot_available error is attached' do
      let(:user) { instance_double(Aeon::User, appointments: user_appointments) }
      let(:user_appointments) { instance_double(Aeon::AppointmentFinders) }
      let(:appointment) do
        build(:aeon_appointment, reading_room: reading_room, start_time: start_time, stop_time: stop_time, user: user)
      end
      let(:start_time) { Time.zone.parse('2026-03-16T09:00:00-07:00') }
      let(:stop_time)  { Time.zone.parse('2026-03-16T16:45:00-07:00') }

      before do
        allow(user_appointments).to receive(:for_reading_room).with(reading_room).and_return([])
        allow(reading_room).to receive(:available_appointments).with(start_time.to_date, include_next_available: false).and_return([])
      end

      it 'attaches the error to :date for day-only reading rooms' do
        expect(appointment).not_to be_valid
        expect(appointment.errors[:date]).to include('is not available')
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

  describe '#item_limit' do
    it 'returns the reading room item limit' do
      reading_room = build(:aeon_reading_room)
      appointment = build(:aeon_appointment, reading_room: reading_room)

      expect(appointment.item_limit).to eq(10)
    end

    context 'with a user who has a custom request limit' do
      let(:user) { instance_double(Aeon::User, request_limit: 22) }
      let(:reading_room) { build(:aeon_reading_room) }
      let(:appointment) { build(:aeon_appointment, reading_room: reading_room, user: user) }

      it 'returns the user request limit' do
        expect(appointment.item_limit).to eq(22)
      end
    end

    context 'with a user who has a huge request limit' do
      let(:user) { instance_double(Aeon::User, request_limit: 1500) }
      let(:reading_room) { build(:aeon_reading_room) }
      let(:appointment) { build(:aeon_appointment, reading_room: reading_room, user: user) }

      it 'returns the user request limit' do
        expect(appointment.item_limit).to be_nil
      end
    end
  end
end
