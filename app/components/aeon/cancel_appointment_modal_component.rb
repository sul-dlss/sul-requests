# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class CancelAppointmentModalComponent < Aeon::AppointmentComponent
    attr_reader :appointment, :id

    def initialize(appointment:, id: nil)
      @appointment = appointment
      @id = id
      super(appointment: @appointment)
    end
  end
end
