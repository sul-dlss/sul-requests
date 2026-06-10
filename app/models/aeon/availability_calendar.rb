# frozen_string_literal: true

module Aeon
  # Computes which dates in a range have no room left for another booking,
  # given a user's existing appointments and the reading room's closures.
  #
  # A date has "no room" when the longest free gap inside the reading room's
  # open hours is shorter than the room's minimum appointment length.
  class AvailabilityCalendar
    def initialize(reading_room:, user_appointments: [])
      @reading_room = reading_room
      @user_appointments = user_appointments
    end

    def dates_with_no_room(date_range)
      return [] unless reading_room

      date_range.select { |date| no_room?(date) }
    end

    def no_room?(date)
      hours = reading_room.open_hours_on(date)
      # No open hours means nothing to block out
      return false unless hours

      open_range = hours.range_on(date)
      conflicts = conflicts_on(date, open_range)
      return false if conflicts.empty?

      largest_gap_seconds(open_range, conflicts) < min_appointment_seconds
    end

    private

    attr_reader :reading_room, :user_appointments

    def conflicts_on(date, open_range)
      ranges = appointment_ranges_on(date) + closure_ranges_in(open_range)
      ranges.select { |r| r.begin < open_range.end && r.end > open_range.begin }
    end

    def appointment_ranges_on(date)
      user_appointments.select { |a| a.date == date }.map { |a| a.start_time..a.stop_time }
    end

    def closure_ranges_in(open_range)
      (reading_room.closures || []).filter_map { |c| c.range if c.range.overlap?(open_range) }
    end

    def largest_gap_seconds(open_range, conflicts)
      open_end = open_range.end
      cursor = open_range.begin
      largest = 0
      merge_ranges(conflicts.sort_by(&:begin)).each do |c|
        gap = [c.begin, open_end].min - cursor
        largest = gap if gap > largest
        cursor = [cursor, c.end].max
        break if cursor >= open_end
      end
      [open_end - cursor, largest].max
    end

    def merge_ranges(sorted)
      sorted.each_with_object([]) do |r, merged|
        if merged.last && merged.last.end >= r.begin
          merged[-1] = merged.last.begin..[merged.last.end, r.end].max
        else
          merged << r
        end
      end
    end

    def min_appointment_seconds
      (reading_room.min_appointment_length || 0) * 60
    end
  end
end
