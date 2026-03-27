# frozen_string_literal: true

module Aeon
  # Render a group of requests that share the same title and request type
  class RequestGroupComponent < ViewComponent::Base
    attr_reader :request_group

    delegate :appointment_reading_room, :base_callnumber, :requests, :status_request, :title, to: :request_group

    def initialize(request_group:)
      @request_group = request_group
    end

    def render?
      requests.present?
    end
  end
end
