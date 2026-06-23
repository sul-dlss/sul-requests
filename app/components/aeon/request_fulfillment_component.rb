# frozen_string_literal: true

module Aeon
  # Render the fulfillment context for a request.
  # E.g., appointment time reading-room requests, delivery status for digitization.
  class RequestFulfillmentComponent < ViewComponent::Base
    attr_reader :request

    delegate :appointment?, :cancelled_by_staff?, :delivered_date, :digital?, :saved_for_later?,
             :scan_delivered?, :submitted?, to: :request

    def initialize(request:)
      @request = request
    end

    def render?
      return false if saved_for_later?

      mode.present?
    end

    def mode
      return :cancelled_by_staff if cancelled_by_staff?
      return :appointment if appointment?
      return :delivered if digital? && scan_delivered?

      :delivery_pending if digital? && submitted?
    end
  end
end
