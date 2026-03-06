# frozen_string_literal: true

module Aeon
  # Render an accordion item for a digitization form step.
  class AppointmentFormItemComponent < ViewComponent::Base
    attr_reader :title, :dom_id, :object, :base_name, :series, :subseries, :appointments

    def initialize(title:, dom_id:, object: nil, base_name: nil, series: nil, subseries: nil, reading_room_id: nil, appointments: []) # rubocop:disable Metrics/ParameterLists
      @title = title
      @dom_id = dom_id
      @object = object
      @base_name = base_name || "item[#{dom_id}]"
      @series = series
      @subseries = subseries
      @appointments = appointments
      @reading_room_id = reading_room_id
    end

    def new_appointment_path
      new_aeon_appointment_path(reading_room_id: @reading_room_id)
    end

    def appointment_options_for_select # rubocop:disable Metrics/AbcSize
      options_for_select(
        appointments.select(&:editable?).sort_by(&:sort_key).map do |a|
          [
            "#{a.start_time.strftime('%b %d, %Y')} ● #{a.start_time.strftime('%l:%M %p -')}#{a.stop_time.strftime('%l:%M %p')} (#{pluralize(
              a.requests.length, 'item'
            )})", a.id, { data: { 'sort-key' => a.sort_key.to_s } }
          ]
        end
      )
    end

    def placeholder
      if appointments.any?
        'Select existing appointment'
      else
        ''
      end
    end
  end
end
