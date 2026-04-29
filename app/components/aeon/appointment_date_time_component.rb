# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class AppointmentDateTimeComponent < ViewComponent::Base
    attr_reader :appointment, :icon_class

    def initialize(appointment:, icon_class: 'me-2', show_open_hours: true)
      @appointment = appointment
      @icon_class = icon_class
      @show_open_hours = show_open_hours
    end

    def show_open_hours?
      @show_open_hours
    end
  end
end
