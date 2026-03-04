# frozen_string_literal: true

module Aeon
  # Render an accordion item for a digitization form step.
  class AppointmentFormItemComponent < ViewComponent::Base
    attr_reader :title, :dom_id, :base_name, :series, :subseries, :appointments

    def initialize(title:, dom_id:, base_name: nil, series: nil, subseries: nil, reading_room_id: nil, appointments: []) # rubocop:disable Metrics/ParameterLists
      @title = title
      @dom_id = dom_id
      @base_name = base_name || "item[#{dom_id}]"
      @series = series
      @subseries = subseries
      @appointments = appointments
      @reading_room_id = reading_room_id
    end

    def new_appointment_path
      new_aeon_appointment_path(reading_room_id: @reading_room_id)
    end
  end
end
