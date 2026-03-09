# frozen_string_literal: true

module Aeon
  # Render an option for an appointment in the custom appointment select-ish dropdown.
  class AppointmentOptionComponent < ViewComponent::Base
    with_collection_parameter :appointment
    attr_reader :appointment

    def initialize(appointment:, data: {})
      @appointment = appointment
      @data = data
    end
  end
end
