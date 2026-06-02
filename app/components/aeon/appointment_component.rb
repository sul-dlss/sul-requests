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
      return true unless appointment.editable? && saved_for_later?
      return false unless appointment.reading_room.appointment_item_limit

      appointment.requests.count >= appointment.reading_room.appointment_item_limit
    end

    def saved_for_later?
      @drafts ||= current_user.aeon.saved_for_later_requests.reject(&:digital?).any? do |request|
        request.reading_room.id == @appointment.reading_room.id
      end
    end

    def items_path
      aeon_appointment_items_path(sort: 'title', aeon_appointment_id: appointment.id)
    end
  end
end
