# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class AppointmentCancelModalComponent < ViewComponent::Base
    attr_reader :appointment, :id

    def initialize(appointment:, id: nil)
      @appointment = appointment
      @id = id
    end
  end
end
