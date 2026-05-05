# frozen_string_literal: true

# Helpers for building Aeon::Appointment / Aeon::Activity instance_doubles
# that include a derived ScheduledTimeBlock, so callers don't repeat the
# same start_time/stop_time/location data.
module AeonDoubles
  def aeon_appointment_double(start_time:, stop_time:, reading_room:, **overrides)
    block = ScheduledTimeBlock.new(start_time:, stop_time:, location: reading_room.name,
                                   day_only: reading_room.day_only_appointments?)
    instance_double(Aeon::Appointment, start_time:, stop_time:, reading_room:,
                                       scheduled_time_block: block, **overrides)
  end

  def aeon_activity_double(start_time:, stop_time:, location:, **overrides)
    block = ScheduledTimeBlock.new(start_time:, stop_time:, location:, day_only: false)
    instance_double(Aeon::Activity, start_time:, stop_time:, location:,
                                    scheduled_time_block: block, **overrides)
  end
end

RSpec.configure do |config|
  config.include AeonDoubles
end
