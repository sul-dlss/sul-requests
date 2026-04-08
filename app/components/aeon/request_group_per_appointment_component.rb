# frozen_string_literal: true

module Aeon
  # Render a group of requests that share the same title and request type
  # Differs in layout from RequestGroupAppointment
  # Appears on aeon_appointment/index page
  class RequestGroupPerAppointmentComponent < Aeon::RequestGroupComponent
    def initialize(request_group_per_appointment:)
      @request_group = request_group_per_appointment
    end
  end
end
