# frozen_string_literal: true

module Aeon
  # Wraps an Aeon reading room open hours record
  class ReadingRoomOpenHours
    attr_reader :day_of_week, :day_name, :open_time, :close_time

    def self.from_dynamic(dyn)
      new(
        day_of_week: dyn['dayOfWeek'],
        day_name: dyn['dayName'],
        open_time: dyn['openTime'],
        close_time: dyn['closeTime']
      )
    end

    def initialize(day_of_week: nil, day_name: nil, open_time: nil, close_time: nil)
      @day_of_week = day_of_week
      @day_name = day_name
      @open_time = open_time
      @close_time = close_time
    end
  end
end
