# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aeon::ReadingRoom do
  describe '#human_readable_hours' do
    subject(:reading_room) { build(:aeon_reading_room, open_hours: open_hours) }

    let(:open_hours) do
      [
        build(:aeon_reading_room_open_hours, day_of_week: 1, day_name: 'Monday', open_time: Time.zone.parse('09:00'),
                                             close_time: Time.zone.parse('17:00')),
        build(:aeon_reading_room_open_hours, day_of_week: 2, day_name: 'Tuesday', open_time: Time.zone.parse('09:00'),
                                             close_time: Time.zone.parse('17:00')),
        build(:aeon_reading_room_open_hours, day_of_week: 3, day_name: 'Wednesday', open_time: Time.zone.parse('10:00'),
                                             close_time: Time.zone.parse('16:00')),
        build(:aeon_reading_room_open_hours, day_of_week: 4, day_name: 'Thursday', open_time: Time.zone.parse('10:00'),
                                             close_time: Time.zone.parse('12:00')),
        build(:aeon_reading_room_open_hours, day_of_week: 4, day_name: 'Thursday', open_time: Time.zone.parse('13:00'),
                                             close_time: Time.zone.parse('17:00')),
        build(:aeon_reading_room_open_hours, day_of_week: 5, day_name: 'Friday', open_time: Time.zone.parse('09:00'),
                                             close_time: Time.zone.parse('17:00'))
      ]
    end

    it 'combines sequential days with the same hours and groups multiple hours for the same day' do
      expect(reading_room.human_readable_hours).to eq([
        'Monday - Tuesday, 9:00 - 5:00 pm',
        'Wednesday, 10:00 - 4:00 pm',
        'Thursday, 10:00 - 12:00 pm and 1:00 - 5:00 pm',
        'Friday, 9:00 - 5:00 pm'
      ].join(', '))
    end
  end
end
