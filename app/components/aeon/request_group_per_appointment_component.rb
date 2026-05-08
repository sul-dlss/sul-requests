# frozen_string_literal: true

module Aeon
  # Render a group of requests that share the same title and request type
  # Differs in layout from RequestGroupAppointment
  # Appears on aeon_appointment/index page
  class RequestGroupPerAppointmentComponent < Aeon::RequestGroupComponent
    with_collection_parameter :request_group

    def initialize(request_group:)
      @request_group = request_group
    end

    def group_id
      return request_group.first.activity_id if request_group.activity?

      request_group.first.appointment_id
    end
  end
end
