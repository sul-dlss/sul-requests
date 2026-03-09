# frozen_string_literal: true

module Aeon
  # Render a group of requests that share the same title and request type
  class RequestGroupComponent < ViewComponent::Base
    attr_reader :request_group

    delegate :title, :call_number, :document_type, :date, :digital?, :ead_number, :requests, to: :request_group

    def initialize(request_group:)
      @request_group = request_group
    end

    def render?
      requests.present?
    end

    def status_class
      'draft'
    end

    def status_text
      digital? ? 'Digitization' : 'Reading room use'
    end
  end
end
