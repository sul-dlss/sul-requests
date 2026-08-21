# frozen_string_literal: true

module Aeon
  class AppointmentDateTimeComponentPreview < ViewComponent::Preview
    layout 'lookbook'

    # @!group Activity
    def single_day_activity
      activity = FactoryBot.build(:aeon_activity)

      render Aeon::AppointmentDateTimeComponent.new(appointment: activity, location: activity.location)
    end

    def multi_day_activity
      activity = FactoryBot.build(:aeon_activity, stop_time: Time.zone.parse('2026-02-25T13:00:00'))

      render Aeon::AppointmentDateTimeComponent.new(appointment: activity, location: activity.location)
    end
    # @!endgroup
  end
end
