# frozen_string_literal: true

module Aeon
  # Render an option for an appointment in the custom appointment select-ish dropdown.
  class AppointmentOptionComponent < ViewComponent::Base
    with_collection_parameter :appointment
    attr_reader :appointment, :name, :data_action

    delegate :item_limit, to: :appointment

    def initialize(appointment:, name: nil, data: {}, data_action: nil)
      @appointment = appointment
      @name = name
      @data = data
      @data_action = data_action
    end

    def at_limit?
      return false unless item_limit

      appointment.requests.count >= item_limit
    end
  end
end
