# frozen_string_literal: true

module Aeon
  # Render section of modal responsible for displaying appointment selection or
  class AppointmentSelectionComponent < ViewComponent::Base
    def initialize(appointment:)
      @appointment = appointment
    end

    def existing_appointment?
      @appointment.date.present?
    end
  end
end
