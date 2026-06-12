# frozen_string_literal: true

FactoryBot.define do
  factory :remote_aeon_appointment, class: 'StubAeonClient::Appointment' do
    username { 'nerdsquirrel@stanford.edu' }
    startTime { Time.zone.parse('2024-03-11T20:00:00Z') }
    stopTime { Time.zone.parse('2024-03-11T20:15:00Z') }
  end
end
