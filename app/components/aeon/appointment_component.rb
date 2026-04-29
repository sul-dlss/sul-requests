# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class AppointmentComponent < ViewComponent::Base
    attr_reader :appointment

    def initialize(appointment:)
      @appointment = appointment
    end

    def add_item_disabled?
      return true unless appointment.editable?
      return false unless appointment.reading_room.appointment_item_limit

      appointment.requests.count >= appointment.reading_room.appointment_item_limit
    end

    def items_path
      aeon_appointment_items_path(sort: 'title', aeon_appointment_id: appointment.id)
    end
  end
end
