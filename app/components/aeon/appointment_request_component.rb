# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class AppointmentRequestComponent < ViewComponent::Base
    attr_reader :request

    def initialize(request:)
      @request = request
    end
  end
end
