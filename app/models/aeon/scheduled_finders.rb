# frozen_string_literal: true

module Aeon
  # Shared finders for collections of time-scheduled items (each item must
  # respond to `start_time`). Includers must be Enumerable and accept an
  # array of items in their initializer.
  module ScheduledFinders
    # Items that start within `within`, plus items already in progress, sorted
    # by start time; if none fall in that range, falls back to the next
    # `fallback` items. An item is in progress until its stop time passes.
    def upcoming(within:, fallback:)
      now = Time.zone.now
      future = select { |item| unfinished?(item, now) }.sort_by(&:start_time)
      cutoff = within.from_now
      in_window = future.take_while { |item| item.start_time <= cutoff }
      in_window.any? ? in_window : future.first(fallback)
    end

    private

    def unfinished?(item, now)
      return false unless item.start_time

      item.start_time >= now || (item.stop_time.present? && item.stop_time >= now)
    end
  end
end
