# frozen_string_literal: true

module AppointmentTime
  # Renders a ScheduledTimeBlock as a heading-level presentation with calendar/clock
  # icons. Designed to anchor a card or modal title; pass with_location: true to include
  # the location as a third icon-prefixed segment.
  class HeadingComponent < ViewComponent::Base
    attr_reader :time_block, :icon_class

    def initialize(time_block:, icon_class: 'me-2', show_open_hours: true, with_location: false)
      @time_block = time_block
      @icon_class = icon_class
      @show_open_hours = show_open_hours
      @with_location = with_location
    end

    def render?
      @time_block&.renderable?
    end

    def show_open_hours?
      @show_open_hours
    end

    def with_location?
      @with_location && time_block.location.present?
    end

    def date
      l(time_block.start_time, format: :date_only)
    end

    def time_range
      "#{l(time_block.start_time, format: :time_only)} - #{l(time_block.stop_time, format: :time_only)}"
    end
  end
end
