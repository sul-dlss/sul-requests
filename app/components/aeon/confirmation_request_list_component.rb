# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class ConfirmationRequestListComponent < ViewComponent::Base
    def initialize(requests:, digitization:, drafts: false)
      @requests = requests
      @digitization = digitization
      @drafts = drafts
    end

    def render?
      @requests.any?
    end

    def title
      return 'Drafts (Requests not completed)' if @drafts
      return 'Digitization requests' if @digitization

      'Appointments'
    end

    def accordion_name(index)
      "accordion#{@drafts ? 'Draft' : 'Request'}#{index}"
    end

    attr_reader :requests
  end
end
