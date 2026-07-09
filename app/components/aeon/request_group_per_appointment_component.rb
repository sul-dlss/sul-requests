# frozen_string_literal: true

module Aeon
  # Render a group of requests that share the same title and request type
  # Differs in layout from RequestGroupAppointment
  # Appears on aeon_appointment/index page
  class RequestGroupPerAppointmentComponent < Aeon::RequestGroupComponent
    with_collection_parameter :request_group

    attr_reader :classes

    def initialize(request_group:, classes: %w[card rounded-0 px-3 py-2 mb-3 border-0 border-top border-first-child-top-0 mb-last-child-0])
      @request_group = request_group
      @classes = Array(classes)
    end

    def group_id
      return request_group.first.activity_id if request_group.activity?

      request_group.first.appointment_id
    end
  end
end
