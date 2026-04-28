# frozen_string_literal: true

# dropdown, confirmation screen appointment display
class AppointmentTimeRangeComponent < ViewComponent::Base
  def initialize(appointment:)
    @appointment = appointment
  end

  def date
    l(@appointment.start_time, format: :date_only)
  end

  def time_range
    "#{l(@appointment.start_time, format: :time_only)} - #{l(@appointment.stop_time, format: :time_only)}"
  end

  def call
    return tag.span(date) if @appointment.reading_room.day_only_appointments?

    tag.span(date) + tag.i(class: 'bi bi-dot') + tag.span(time_range)
  end
end
