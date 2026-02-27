# frozen_string_literal: true

module Aeon
  # Render request status information about missing fields/requirements
  class RequestMissingInformationComponent < ViewComponent::Base
    attr_reader :request

    delegate :appointment?, :call_number, :digital?, :draft?, :item_url, :pages, :physical?, to: :request

    def initialize(request:)
      @request = request
    end

    def render?
      draft? && missing_information_message.present?
    end

    def missing_information_message
      # TODO: Handle 'request type not specified' once we understand how to explicitly specify a reading room request.
      if digital?
        'Pages/instructions not specified.' if pages.blank?
      else
        reading_room_message
      end
    end

    # Reading room: "Items and details not specified". What are details for a reading room request?
    #                Additional information? Is that really required? Details = appointment?

    def reading_room_message
      if item_missing?
        return 'Item and details not specified.' if details_missing?

        return 'Item not specified.'
      end

      appointment_status_message
    end

    def appointment_status_message
      'Appointment not scheduled.' unless appointment?
    end

    def item_missing?
      item_url.blank? || call_number.blank?
    end

    def details_missing?
      if digital?
        pages.nil?
      else
        !appointment?
      end
    end
  end
end
