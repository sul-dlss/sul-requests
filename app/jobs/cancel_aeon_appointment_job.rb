# frozen_string_literal: true

##
# Rails Job to submit a hold request to Folio for processing
class CancelAeonAppointmentJob < ApplicationJob
  queue_as :default

  def perform(appointment)
    appointment.requests.each do |request|
      request.update(appointment_id: nil)
    end
    aeon_client.cancel_appointment(appointment.id)
  end

  def aeon_client
    @aeon_client ||= AeonClient.new
  end
end
