# frozen_string_literal: true

# dropdown, confirmation screen appointment display
class AppointmentTimeRangeComponent < ViewComponent::Base
  def initialize(appointment:)
    @appointment = appointment
  end

  def date
    @appointment.start_time.strftime('%b %-d, %Y')
  end

  def time_range
    "#{@appointment.start_time.strftime('%l:%M %p')} - #{@appointment.stop_time.strftime('%l:%M %p')}"
  end

  def call
    tag.span(date) + tag.i(class: 'bi bi-dot') + tag.span(time_range)
  end
end
