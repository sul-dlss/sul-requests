# frozen_string_literal: true

# A scheduled time block: a date and optional time range with a location.
# Produced by Aeon::Appointment, Aeon::Activity, and Aeon::Request, and
# consumed by the AppointmentTime::* presenter components.
ScheduledTimeBlock = Data.define(:start_time, :stop_time, :location, :day_only) do
  def renderable? = start_time.present?
  def date_only? = day_only
  def time_of_day? = !day_only && start_time.present? && stop_time.present?
end
