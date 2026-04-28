# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class AppointmentComponent < ViewComponent::Base
    attr_reader :appointment

    def initialize(appointment:)
      @appointment = appointment
    end

    def time_range_html(margin: 'me-2')
      tag.span do
        if appointment.reading_room.day_only_appointments?
          tag.i(class: "bi bi-clock #{margin}") + "Open hours: #{appointment_time_range}"
        else
          tag.i(class: "bi bi-clock #{margin}") + appointment_time_range
        end
      end
    end

    def appointment_time_range
      start = l(appointment.start_time, format: :time_only)
      stop = l(appointment.stop_time, format: :time_only)

      "#{start} - #{stop}"
    end

    def appointment_date
      l(appointment.start_time, format: :date_only)
    end

    def add_item_disabled?
      return true unless appointment.editable?
      return false unless appointment.reading_room.appointment_item_limit

      appointment.requests.count >= appointment.reading_room.appointment_item_limit
    end

    def items_path
      aeon_appointment_items_path(sort: 'title', aeon_appointment_id: appointment.id)
    end
  end
end
