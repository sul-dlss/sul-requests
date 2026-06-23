# frozen_string_literal: true

# dropdown, confirmation screen appointment display
class AppointmentTimeRangeComponent < ViewComponent::Base
  def initialize(appointment:, show_hours: false, location: nil, emphasize_date: false)
    @appointment = appointment
    @emphasize_date = emphasize_date
    @show_hours = show_hours
    @location = location
  end

  def date
    l(@appointment.start_time, format: :date_only)
  end

  def time_range
    "#{l(@appointment.start_time, format: :time_only)} - #{l(@appointment.stop_time, format: :time_only)}"
  end

  def show_hours?
    @show_hours || !@appointment.reading_room.day_only_appointments?
  end

  def call
    values = [tag.span(date, class: ('fw-semibold' if @emphasize_date))]
    values << tag.span(time_range) if show_hours?
    values << tag.span(@location) if @location

    safe_join(values, tag.i(class: 'bi bi-dot'))
  end
end
