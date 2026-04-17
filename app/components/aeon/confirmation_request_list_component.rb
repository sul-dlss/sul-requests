# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class ConfirmationRequestListComponent < ViewComponent::Base
    def initialize(requests:, digitization:)
      @requests = requests
      @digitization = digitization
    end

    def render?
      @requests.any?
    end

    def title
      return 'Digitization requests' if @digitization

      'Appointments'
    end

    def accordion_name(index)
      "accordionRequest#{index}"
    end

    attr_reader :requests
  end
end
