# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

unless Rails.env.production?
  StubAeonClient::ReadingRoom.destroy_all
  StubAeonClient::Queue.destroy_all

  JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'reading_rooms.json'))).each do |reading_room_data|
    StubAeonClient::ReadingRoom.create!(id: reading_room_data['id'], data: reading_room_data.except('id'), closures: [])
  end

  JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'queues.json'))).each do |queue_data|
    StubAeonClient::Queue.create!(id: queue_data.dig('queue', 'id'), data: queue_data['queue'].except('id'))
  end
end
