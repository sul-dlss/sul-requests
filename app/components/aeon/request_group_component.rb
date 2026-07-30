# frozen_string_literal: true

module Aeon
  # Render a group of requests that share the same title and request type
  class RequestGroupComponent < ViewComponent::Base
    attr_reader :request_group, :element

    delegate :appointment_reading_room, :base_callnumber, :requests, :status_request, :title, :digital?, :saved_for_later?,
             to: :request_group

    def initialize(request_group:, element: 'div')
      @request_group = request_group
      @element = element
    end

    def render?
      requests.present?
    end

    def show_more?
      requests.first.cancelled? || requests.first.completed?
    end

    def status_text
      if digital?
        'Digitization'
      else
        'Reading room use'
      end
    end
  end
end
