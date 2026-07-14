# frozen_string_literal: true

module Aeon
  # Render a request for an appointment
  class RequestGroupPerAppointmentItemComponent < Aeon::RequestGroupItemComponent
    with_collection_parameter :request

    def initialize(request:, classes: [])
      super
    end
  end
end
