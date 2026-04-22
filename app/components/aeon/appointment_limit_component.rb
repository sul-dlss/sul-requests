# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class AppointmentLimitComponent < ViewComponent::Base
    attr_reader :count, :limit, :label, :data

    def self.from_appointment(appointment, **)
      new(count: appointment.requests.count, limit: appointment.reading_room.appointment_item_limit, **)
    end

    def initialize(count:, limit:, data: {})
      @count = count
      @limit = limit
      @data = data
    end

    def limit?
      limit.present?
    end
  end
end
