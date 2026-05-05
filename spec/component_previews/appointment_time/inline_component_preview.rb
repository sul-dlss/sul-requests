# frozen_string_literal: true

module AppointmentTime
  class InlineComponentPreview < ViewComponent::Preview
    layout 'lookbook'

    # @!group Variations
    def with_hours
      render AppointmentTime::InlineComponent.new(time_block: build_time_block)
    end

    def with_location
      render AppointmentTime::InlineComponent.new(time_block: build_time_block, with_location: true)
    end

    def date_only
      render AppointmentTime::InlineComponent.new(time_block: build_time_block(day_only: true), with_location: true)
    end

    def empty_block_does_not_render
      render AppointmentTime::InlineComponent.new(time_block: build_time_block(start_time: nil))
    end

    def nil_block_does_not_render
      render AppointmentTime::InlineComponent.new(time_block: nil)
    end
    # @!endgroup

    private

    def build_time_block(start_time: 1.day.from_now.change(hour: 10), location: 'Special Collections', day_only: false)
      ScheduledTimeBlock.new(
        start_time:,
        stop_time: start_time && (start_time + 2.hours),
        location:,
        day_only:
      )
    end
  end
end
