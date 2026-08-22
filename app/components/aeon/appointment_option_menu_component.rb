# frozen_string_literal: true

module Aeon
  # Render an option for an appointment in the custom appointment select-ish dropdown.
  class AppointmentOptionMenuComponent < ViewComponent::Base
    attr_reader :appointments, :name, :data_action, :menu_classes

    def initialize(appointments:, name: nil, data_action: nil, menu_classes: [])
      @appointments = appointments
      @name = name
      @data_action = data_action
      @menu_classes = ['dropdown-menu'] + Array(menu_classes)
    end

    def selectable_appointments
      appointments.select(&:editable?)
    end

    def non_selectable_appointments
      appointments.reject(&:editable?)
    end

    def lead_time
      appointments.first&.reading_room&.appointment_min_lead_days
    end
  end
end
