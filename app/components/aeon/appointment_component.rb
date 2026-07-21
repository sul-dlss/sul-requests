# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class AppointmentComponent < ViewComponent::Base
    attr_reader :appointment, :all_requests

    delegate :current_user, to: :helpers
    delegate :reading_room_id, to: :appointment

    def initialize(appointment:, all_requests: nil)
      @appointment = appointment
      @all_requests = all_requests
    end

    def add_item_allowed?
      return false unless helpers.can?(:update, appointment)

      appointment.item_limit.nil? || appointment.requests.count < appointment.item_limit
    end

    def eligible_saved_for_later_requests
      return [] unless all_requests

      @eligible_saved_for_later_requests ||= all_requests.saved_for_later.for_reading_room(@appointment.reading_room)
    end

    def items_path
      aeon_appointment_items_path(sort: 'title', aeon_appointment_id: appointment.id)
    end
  end
end
