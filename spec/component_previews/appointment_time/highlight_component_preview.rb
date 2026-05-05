# frozen_string_literal: true

module AppointmentTime
  class HighlightComponentPreview < ViewComponent::Preview
    layout 'lookbook'

    # @!group Variations
    def default
      render AppointmentTime::HighlightComponent.new(time_block: build_time_block)
    end

    def with_location
      render AppointmentTime::HighlightComponent.new(time_block: build_time_block, with_location: true)
    end

    def date_only
      render AppointmentTime::HighlightComponent.new(time_block: build_time_block(day_only: true))
    end

    def empty_block_does_not_render
      render AppointmentTime::HighlightComponent.new(time_block: build_time_block(start_time: nil))
    end

    def nil_block_does_not_render
      render AppointmentTime::HighlightComponent.new(time_block: nil)
    end
    # @!endgroup

    private

    def build_time_block(start_time: 1.day.from_now.change(hour: 10, min: 30), location: 'Field Reading Room', day_only: false)
      ScheduledTimeBlock.new(
        start_time:,
        stop_time: start_time && (start_time + 90.minutes),
        location:,
        day_only:
      )
    end
  end
end
