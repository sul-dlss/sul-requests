# frozen_string_literal: true

module Aeon
  # Render Aeon request "saved for later" confirmation message
  class ConfirmationSavedForLaterComponent < ViewComponent::Base
    attr_reader :request_group

    delegate :digital?, to: :request_group

    def initialize(request_group:)
      @request_group = request_group
    end

    def render?
      @request_group.draft_requests.present?
    end

    def submitted_requests?
      request_group.submitted_requests.present?
    end

    def saved_count
      @request_group.draft_requests.count
    end
  end
end
