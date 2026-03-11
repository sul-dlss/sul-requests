# frozen_string_literal: true

module Aeon
  # Render request card
  class RequestComponent < ViewComponent::Base
    attr_reader :request

    delegate :call_number, :date, :document_type, :title,
             :transaction_date, :transaction_number, :transaction_status, to: :request

    def initialize(request:)
      @request = request
    end

    def thumbnail?
      # TODO: fill in data
      [true, false].sample
    end
  end
end
