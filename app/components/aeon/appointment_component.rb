# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class AppointmentComponent < ViewComponent::Base
    attr_reader :appointment

    def initialize(appointment:)
      @appointment = appointment
    end

    def appointment_time_range
      start = l(appointment.start_time, format: :time_only)
      stop = l(appointment.stop_time, format: :time_only)

      if appointment.reading_room.day_only_appointments?
        "Open hours: #{start} - #{stop}"
      else
        "#{start} - #{stop}"
      end
    end

    def appointment_date
      l(appointment.start_time, format: :date_only)
    end

    def add_item_disabled?
      return true unless appointment.editable?
      return false unless appointment.reading_room.appointment_item_limit

      appointment.requests.count >= appointment.reading_room.appointment_item_limit
    end

    def add_items_path
      aeon_requests_path(kind: 'drafts', filter: 'reading_room', sort: 'title', appointment_id: appointment.id)
    end
  end
end
