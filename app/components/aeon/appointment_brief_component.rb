# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class AppointmentBriefComponent < Aeon::AppointmentComponent
    with_collection_parameter :appointment

    def total_item_limit_percentage
      appointment.requests.count / appointment.reading_room.appointment_item_limit
    end

    def badge_classes
      if total_item_limit_percentage >= 1
        'bg-danger-subtle'
      elsif total_item_limit_percentage >= 0.8
        'bg-warning-subtle'
      else
        'bg-success-subtle text-dark'
      end
    end
  end
end
