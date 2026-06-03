# frozen_string_literal: true

module Aeon
  # Render aeon apointment card for the sidebar
  class AppointmentSidebarComponent < ViewComponent::Base
    with_collection_parameter :appointment
    attr_reader :appointment

    def initialize(appointment:)
      @appointment = appointment
    end
  end
end
