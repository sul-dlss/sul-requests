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

    def percentage
      (count * 100) / limit
    end

    def bar_color
      if percentage >= 100
        'text-bg-danger'
      elsif percentage >= 75
        'text-bg-warning'
      else
        'text-bg-success'
      end
    end
  end
end
