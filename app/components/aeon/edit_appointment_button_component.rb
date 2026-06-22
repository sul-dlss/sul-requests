# frozen_string_literal: true

module Aeon
  # Edit-appointment button that opens the edit modal.
  class EditAppointmentButtonComponent < ViewComponent::Base
    attr_reader :appointment

    def initialize(appointment:)
      @appointment = appointment
    end

    def render?
      helpers.can?(:update, appointment)
    end
  end
end
