# frozen_string_literal: true

module Aeon
  # Wraps an Aeon reading room closures
  ReadingRoomClosures = Data.define(:start_date, :end_date) do
    def self.from_dynamic(dyn)
      new(
        start_date: Time.zone.parse(dyn['startDate']),
        end_date: Time.zone.parse(dyn['endDate'])
      )
    end

    delegate :cover?, to: :range

    def range
      start_date..end_date
    end
  end
end
