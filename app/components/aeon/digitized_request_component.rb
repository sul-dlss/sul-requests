# frozen_string_literal: true

module Aeon
  # Render digitized request card
  class DigitizedRequestComponent < ViewComponent::Base
    attr_reader :request

    def initialize(request:)
      @request = request
    end
  end
end
