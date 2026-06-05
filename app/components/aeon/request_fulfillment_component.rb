# frozen_string_literal: true

module Aeon
  # Render the fulfillment context for a request.
  # E.g., appointment time reading-room requests, delivery status for digitization.
  class RequestFulfillmentComponent < ViewComponent::Base
    attr_reader :request

    delegate :appointment?, :cancelled_by_staff?, :digital?, :draft?, :scan_delivered?, :submitted?,
             :photoduplication_date, :transaction_date, to: :request

    def initialize(request:)
      @request = request
    end

    def render?
      return false if draft?

      mode.present?
    end

    def delivered_date
      photoduplication_date.presence || transaction_date
    end

    def mode
      return :cancelled_by_staff if cancelled_by_staff?
      return :appointment if appointment?
      return :delivered if digital? && scan_delivered?

      :delivery_pending if digital? && submitted?
    end
  end
end
