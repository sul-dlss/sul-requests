# frozen_string_literal: true

FactoryBot.define do
  mock_data = [
    { 'discoveryDisplayName' => 'Classics Library',
      'id' => '8bb5d494-263f-42f0-9a9f-70451530d8a3',
      'code' => 'CLASSICS',
      'pickupLocation' => false,
      'details' => nil },
    { 'discoveryDisplayName' => 'Archive of Recorded Sound',
      'id' => 'faa81922-3da8-4086-a7fa-977d7d3e7977',
      'code' => 'ARS',
      'pickupLocation' => true,
      'details' => nil },
    { 'discoveryDisplayName' => 'Engineering Library (Terman)',
      'id' => 'd0db91bf-90e7-4036-8e91-721001cf52fc',
      'code' => 'ENG',
      'pickupLocation' => true,
      'details' => { 'isDefaultForCampus' => nil, 'isDefaultPickup' => true } },
    { 'discoveryDisplayName' => 'Green Library',
      'id' => 'a5dbb3dc-84f8-4eb3-8bfe-c61f74a9e92d',
      'code' => 'GREEN-LOAN',
      'pickupLocation' => true,
      'details' => { 'isDefaultForCampus' => 'SUL', 'isDefaultPickup' => true } }
  ]
  factory :service_points, class: 'Array' do
    skip_create

    initialize_with do
      mock_data.map do |entry|
        Folio::ServicePoint.new(id: entry.fetch('id'),
                                code: entry.fetch('code'),
                                name: entry.fetch('discoveryDisplayName'),
                                pickup_location: entry.fetch('pickupLocation', false),
                                is_default_pickup: entry.dig('details', 'isDefaultPickup'),
                                is_default_for_campus: entry.dig('details', 'isDefaultForCampus'))
      end
    end
  end
  factory :default_service_points, class: 'Array' do
    skip_create

    initialize_with do
      defaults = mock_data.select { |entry| entry.dig('details', 'isDefaultPickup') == true }
      defaults.map do |entry|
        Folio::ServicePoint.new(id: entry.fetch('id'),
                                code: entry.fetch('code'),
                                name: entry.fetch('discoveryDisplayName'),
                                pickup_location: entry.fetch('pickupLocation', false),
                                is_default_pickup: entry.dig('details', 'isDefaultPickup'),
                                is_default_for_campus: entry.dig('details', 'isDefaultForCampus'))
      end
    end
  end
end
