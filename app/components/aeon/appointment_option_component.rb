# frozen_string_literal: true

module Aeon
  # Render an option for an appointment in the custom appointment select-ish dropdown.
  class AppointmentOptionComponent < ViewComponent::Base
    with_collection_parameter :appointment
    attr_reader :appointment, :name, :data_action

    def initialize(appointment:, name: nil, data: {}, data_action: nil)
      @appointment = appointment
      @name = name
      @data = data
      @data_action = data_action
    end

    def at_limit?
      appointment.requests.count >= (appointment.item_limit || 100)
    end
  end
end
