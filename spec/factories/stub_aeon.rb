# frozen_string_literal: true

FactoryBot.define do
  factory :remote_aeon_appointment, class: 'StubAeonClient::Appointment' do
    username { 'nerdsquirrel@stanford.edu' }
    startTime { Time.zone.parse('2024-03-11T20:00:00Z') }
    stopTime { Time.zone.parse('2024-03-11T20:15:00Z') }
  end

  factory :remote_aeon_activity, class: 'StubAeonClient::Activity' do
    name { 'An Aeon Activity' }
    activityType { 'Class visit' }
    beginDate { Time.zone.parse('2026-02-19T12:00:00') }
    endDate { Time.zone.parse('2026-02-19T13:00:00') }
    active { true }
    activityStatus { 'Pending' }
    location { 'Special Collections' }
    users { [] }
  end
end
