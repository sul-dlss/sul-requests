# frozen_string_literal: true

module AppointmentTime
  # Renders a ScheduledTimeBlock as an emphasized green-themed inline element.
  # Used to mark a confirmed appointment inside a request listing.
  class HighlightComponent < ViewComponent::Base
    attr_reader :time_block

    def initialize(time_block:, with_location: false)
      @time_block = time_block
      @with_location = with_location
    end

    def render?
      @time_block&.renderable?
    end

    def with_location?
      @with_location && time_block.location.present?
    end

    def date
      l(time_block.start_time, format: :date_only)
    end

    def time_range
      return unless time_block.time_of_day?

      start = l(time_block.start_time, format: :time_only).sub(':00', '')
      stop = l(time_block.stop_time, format: :time_only).sub(':00', '')
      "#{start} - #{stop} (#{time_block.start_time.zone})"
    end
  end
end
