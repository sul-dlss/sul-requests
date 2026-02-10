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
      expect(hours.first).to have_attributes(day_name: 'Monday', open_time: '09:00:00')
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
end
