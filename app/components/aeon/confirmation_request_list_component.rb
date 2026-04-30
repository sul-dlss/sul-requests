# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class ConfirmationRequestListComponent < ViewComponent::Base
    delegate :current_user, to: :helpers

    def initialize(requests:, digitization:, activity_id: nil)
      @requests = requests
      @digitization = digitization
      @activity_id = activity_id
    end

    def render?
      @requests.any?
    end

    def title
      return 'Digitization requests' if @digitization
      return activity_title if @activity_id

      'Appointments'
    end

    def activity_title
      activity = current_user.aeon.activities.find { |appt| appt.id == @activity_id.to_i }
      activity.name
    end

    def accordion_name(index)
      "accordionRequest#{index}"
    end

    attr_reader :requests
  end
end
