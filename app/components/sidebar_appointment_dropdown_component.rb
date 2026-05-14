# frozen_string_literal: true

# Render sidebar appointment dropdown
class SidebarAppointmentDropdownComponent < ViewComponent::Base
  attr_reader :request

  def initialize(request:)
    @request = request
  end

  def selectable_appointments
    helpers.current_user.aeon.appointments.select do |appt|
      appt.reading_room.id == request.reading_room.id
    end.select(&:editable?).sort_by(&:sort_key)
  end
end
