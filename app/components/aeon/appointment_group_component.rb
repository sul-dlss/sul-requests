# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class AppointmentGroupComponent < ViewComponent::Base
    attr_reader :appointment_group

    def initialize(appointment_group:, group_classes: [], header_classes: %w[d-flex flex-row justify-content-between])
      @appointment_group = appointment_group
      @group_classes = group_classes
      @header_classes = header_classes
    end

    def appointment_date
      appointment_group.date.strftime('%b %-d, %Y')
    end

    def appointment_reading_room_name
      appointment_group.reading_room&.name
    end
  end
end
