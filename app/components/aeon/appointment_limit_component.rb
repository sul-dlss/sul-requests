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
      @data = progress_bar_data.merge(data)
    end

    def progress_bar_data
     { controller: 'progress-bar', progress_bar_limit_value: limit, progress_bar_count_value: count }
    end

    def limit?
      limit.present?
    end
  end
end
