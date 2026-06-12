# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class AppointmentComponent < ViewComponent::Base
    attr_reader :appointment

    delegate :current_user, to: :helpers

    def initialize(appointment:)
      @appointment = appointment
    end

    def add_item_disabled?
      return true unless helpers.can?(:update, appointment) && saved_for_later?
      return false unless appointment.reading_room.appointment_item_limit

      appointment.requests.count >= appointment.reading_room.appointment_item_limit
    end

    def saved_for_later?
      @saved_for_later ||= current_user.aeon.requests.saved_for_later.for_reading_room(@appointment.reading_room)
    end

    def items_path
      aeon_appointment_items_path(sort: 'title', aeon_appointment_id: appointment.id)
    end
  end
end
