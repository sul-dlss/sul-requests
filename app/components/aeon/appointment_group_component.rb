# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class AppointmentGroupComponent < ViewComponent::Base
    attr_reader :appointment_group

    def initialize(appointment_group:)
      @appointment_group = appointment_group
    end

    def appointment_date
      appointment_group.date.strftime('%b %-d, %Y')
    end

    def appointment_reading_room_name
      appointment_group.reading_room&.name
    end
  end
end
