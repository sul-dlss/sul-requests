# frozen_string_literal: true

module Aeon
  # Delete-appointment button paired with a confirmation modal.
  class DeleteAppointmentButtonComponent < ViewComponent::Base
    attr_reader :appointment

    def initialize(appointment:)
      @appointment = appointment
    end

    def render?
      helpers.can?(:destroy, appointment)
    end

    def modal_id
      "delete-appointment-#{appointment.id}"
    end
  end
end
