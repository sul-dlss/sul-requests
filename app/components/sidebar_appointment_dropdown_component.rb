# frozen_string_literal: true

# Render sidebar appointment dropdown
class SidebarAppointmentDropdownComponent < ViewComponent::Base
  attr_reader :request

  def initialize(request:)
    @request = request
  end

  def render?
    request.reading_room.present?
  end

  def selectable_appointments
    helpers.current_user.aeon.appointments.for_reading_room(request.reading_room).select(&:editable?)
  end
end
