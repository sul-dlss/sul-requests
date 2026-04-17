# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class AppointmentComponent < ViewComponent::Base
    attr_reader :appointment

    def initialize(appointment:)
      @appointment = appointment
    end

    def time_range_html(margin: 'mx-2')
      return if appointment.reading_room.day_only_appointments?

      tag.i(class: "bi bi-clock #{margin}") + appointment_time_range
    end

    def appointment_time_range
      start = l(appointment.start_time, format: :time_only)
      stop = l(appointment.stop_time, format: :time_only)

      "#{start} - #{stop}"
    end

    def add_item_disabled?
      return true unless appointment.editable?

      appointment.requests.count >= appointment.reading_room.appointment_item_limit
    end

    def add_items_path
      draft_aeon_requests_path(filter: 'reading_room', sort: 'title', appointment_id: appointment.id)
    end

    def appointment_date
      l(appointment.start_time, format: :date_only)
    end
  end
end
