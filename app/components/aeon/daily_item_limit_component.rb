# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class DailyItemLimitComponent < ViewComponent::Base
    attr_reader :count, :limit

    def self.from_appointment_group(appointment_group)
      new(count: appointment_group.total_requests_count, limit: appointment_group.reading_room_limit)
    end

    def initialize(count:, limit:)
      @count = count
      @limit = limit
    end

    def render?
      limit.present?
    end

    # We want to show (at most) 5 dots; if the limit is bigger, we'll scale the count + limit appropriately.
    def total_dots(max: 5)
      @total_dots ||= limit.clamp(0, max)
    end

    # .. and if there's at least one item, we should fill at least one dot.
    def filled_dots
      return 0 if count.zero?

      @filled_dots ||= (total_dots * (count / limit.to_f)).to_i.clamp(1, total_dots)
    end

    def dot_used_class
      if filled_dots == total_dots
        'text-danger'
      elsif filled_dots == total_dots - 1
        'text-warning'
      else
        'text-green'
      end
    end
  end
end
