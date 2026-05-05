# frozen_string_literal: true

module AppointmentTime
  # Renders a ScheduledTimeBlock as inline dot-separated text.
  # Used in dropdowns, confirmation lists, the activity picker, and create-flash banners.
  class InlineComponent < ViewComponent::Base
    def initialize(time_block:, with_location: false)
      @time_block = time_block
      @with_location = with_location
    end

    def render?
      @time_block&.renderable?
    end

    def call
      safe_join(segments, tag.i(class: 'bi bi-dot'))
    end

    private

    def segments
      [
        tag.span(date),
        (tag.span(time_range) if @time_block.time_of_day?),
        (tag.span(@time_block.location) if show_location?)
      ].compact
    end

    def show_location?
      @with_location && @time_block.location.present?
    end

    def date
      l(@time_block.start_time, format: :date_only)
    end

    def time_range
      "#{l(@time_block.start_time, format: :time_only)} - #{l(@time_block.stop_time, format: :time_only)}"
    end
  end
end
