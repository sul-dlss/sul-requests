# frozen_string_literal: true

module Aeon
  # Render digitized request card
  class DigitizedRequestComponent < ViewComponent::Base
    attr_reader :request

    delegate :aeon_link, :call_number, :document_type, :title, :transaction_date, :transaction_number, to: :request

    def initialize(request:)
      @request = request
    end
  end
end
