# frozen_string_literal: true

module Aeon
  # Wraps an Aeon reading room closures
  ReadingRoomClosures = Data.define(:start_date, :end_date) do
    def self.from_dynamic(dyn)
      new(
        start_date: dyn['startDate'],
        end_date: dyn['endDate']
      )
    end
  end
end
