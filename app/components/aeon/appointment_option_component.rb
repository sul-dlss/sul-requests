# frozen_string_literal: true

module Aeon
  # Render an option for an appointment in the custom appointment select-ish dropdown.
  class AppointmentOptionComponent < ViewComponent::Base
    with_collection_parameter :appointment
    attr_reader :appointment, :data_action

    def initialize(appointment:, data: {}, data_action: 'appointment-select#select')
      @appointment = appointment
      @data = data
      @data_action = data_action
    end

    def at_limit?
      appointment.requests.count >= (appointment.reading_room.appointment_item_limit || 100)
    end
  end
end
