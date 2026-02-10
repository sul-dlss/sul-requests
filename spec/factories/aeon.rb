# frozen_string_literal: true

FactoryBot.define do
  factory :aeon_reading_room_open_hours, class: 'Aeon::ReadingRoomOpenHours' do
    day_of_week { 1 }
    day_name { 'Monday' }
    open_time { '09:00:00' }
    close_time { '16:45:00' }

    initialize_with { new(**attributes) }
  end

  factory :aeon_reading_room_policy, class: 'Aeon::ReadingRoomPolicy' do
    id { 4 }
    reading_room_id { 5 }
    user_status { nil }
    appointment_required { true }
    appointment_min_lead_days { 5 }
    appointment_max_lead_days { 365 }
    request_min_lead_days { 5 }
    request_max_lead_days { 365 }
    auto_confirm_appointments { false }
    appointment_reminder_days { -1 }
    notify_appointment_received { true }

    initialize_with { new(**attributes) }
  end

  factory :aeon_reading_room, class: 'Aeon::ReadingRoom' do
    id { 5 }
    name { 'Field Reading Room' }
    available_seats { 15 }
    time_zone_id { 'Pacific Standard Time' }
    min_appointment_length { 30 }
    max_appointment_length { 480 }
    appointment_padding { 0 }
    appointment_increment { 15 }
    last_modified_time { Time.zone.parse('2022-09-01T16:13:22.477Z') }
    sites { ['SPECUA'] }
    open_hours { [build(:aeon_reading_room_open_hours)] }
    policies { [build(:aeon_reading_room_policy)] }

    initialize_with { new(**attributes) }
  end

  factory :aeon_appointment, class: 'Aeon::Appointment' do
    id { 23 }
    username { 'nerdsquirrel@stanford.edu' }
    reading_room_id { 5 }
    start_time { Time.zone.parse('2024-03-11T20:00:00Z') }
    stop_time { Time.zone.parse('2024-03-11T20:15:00Z') }
    name { nil }
    available_to_proxies { false }
    appointment_status { 'Confirmed' }
    reading_room { build(:aeon_reading_room) }
    creation_date { Time.zone.parse('2024-03-11T18:33:48.103Z') }

    initialize_with { new(**attributes) }
  end

  factory :aeon_request, class: 'Aeon::Request' do
    transaction_number { 307 }
    transaction_status { 8 }
    transaction_date { Time.zone.parse('2024-03-11T23:35:01.23Z') }
    creation_date { Time.zone.parse('2024-03-11T18:42:51.95Z') }
    title { 'Throwing a sinker ball at 94 mpg with wicked movement' }
    author { nil }
    call_number { nil }
    document_type { nil }
    format { nil }
    location { nil }
    pages { nil }
    shipping_option { nil }
    volume { nil }
    aeon_link { 'https://searchworks.stanford.edu/view/12345678' }
    date { nil }
    appointment_id { 23 }
    appointment { build(:aeon_appointment) }

    initialize_with { new(**attributes) }

    trait :without_appointment do
      appointment_id { nil }
      appointment { nil }
    end

    trait :digitized do
      shipping_option { 'Electronic Delivery' }
      appointment_id { nil }
      appointment { nil }
    end
  end
end
