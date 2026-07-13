# frozen_string_literal: true

module DatePicker
  # Default schedule policy for DatePickerComponent: today through today + 3 years,
  # all weekdays open, no closures, no availability lookup.
  class Schedule
    def initialize(min: nil, max: nil)
      @min = min
      @max = max
    end

    def min
      to_iso(@min) || default_min
    end

    def max
      to_iso(@max) || default_max
    end

    def open_days
      Date::DAYNAMES
    end

    def availability_url
      nil
    end

    def disabled_dates
      []
    end

    def default_min
      Time.zone.today.iso8601
    end

    def default_max
      (Time.zone.today + 3.years).iso8601
    end

    private

    def to_iso(value)
      return if value.blank?

      value.respond_to?(:iso8601) ? value.iso8601 : value.to_s
    end
  end
end
