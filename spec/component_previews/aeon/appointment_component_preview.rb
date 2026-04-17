# frozen_string_literal: true

module Aeon
  class AppointmentComponentPreview < ViewComponent::Preview
    layout 'lookbook'

    def empty
      appointment = FactoryBot.build(:aeon_appointment)
      render Aeon::AppointmentComponent.new(appointment: appointment)
    end

    def searchworks_item_request
      appointment = FactoryBot.build(:aeon_appointment)
      appointment.requests = [FactoryBot.build(:aeon_request, call_number: 'XYZ 123')]
      render Aeon::AppointmentComponent.new(appointment: appointment)
    end

    def multi_box_ead_request
      appointment = FactoryBot.build(:aeon_appointment)
      appointment.requests = [
        FactoryBot.build(:aeon_request, :ead, call_number: 'Box 1'),
        FactoryBot.build(:aeon_request, :ead, call_number: 'Box 2')
      ]
      render Aeon::AppointmentComponent.new(appointment: appointment)
    end

    def multi_item_ead_request
      appointment = FactoryBot.build(:aeon_appointment)
      appointment.requests = [
        FactoryBot.build(:aeon_request, :ead, ead_number: 'M1234', call_number: 'Box 2'),
        FactoryBot.build(:aeon_request, :ead, ead_number: 'SC987', item_title: 'Some other collection', call_number: 'Box 53'),
        FactoryBot.build(:aeon_request, :ead, ead_number: 'SC987', item_title: 'Some other collection', call_number: 'Box 54')
      ]
      render Aeon::AppointmentComponent.new(appointment: appointment)
    end
  end
end
