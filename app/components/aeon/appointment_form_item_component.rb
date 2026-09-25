# frozen_string_literal: true

module Aeon
  # Render an accordion item for a digitization form step.
  class AppointmentFormItemComponent < ViewComponent::Base
    class << self
      def for_request(request:, base_name: 'aeon_request', **)
        new(request:, base_name:, **)
      end

      def for_selectable_item(item:, **)
        new(dom_id: item.id, item_label: item.callnumber, **)
      end

      def template(base_name: 'patron_request[aeon_item][__ID__]', **)
        new(dom_id: '__ID__', item_label: '__TITLE__', base_name:, **)
      end
    end

    private_class_method :new

    attr_reader :item_label, :dom_id, :request, :base_name, :appointments

    def initialize(dom_id:, item_label: nil, request: nil, base_name: nil, reading_room_id: nil, appointments: []) # rubocop:disable Metrics/ParameterLists
      @item_label = item_label.presence || '(no call number)'
      @dom_id = dom_id
      @request = request
      @base_name = base_name || "item[#{dom_id}]"
      @appointments = appointments
      @reading_room_id = reading_room_id
    end

    def new_appointment_path
      new_aeon_appointment_path(aeon_appointment: { reading_room_id: @reading_room_id })
    end

    def selectable_appointments
      appointments.select(&:editable?)
    end

    def save_for_later?
      request.nil?
    end

    def item_label_element_id
      "appointment-item-label-#{dom_id}"
    end

    def delete_label_element_id
      "appointment-delete-label-#{dom_id}"
    end
  end
end
