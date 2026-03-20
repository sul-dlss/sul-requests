# frozen_string_literal: true

##
# Rails Job to submit a hold request to Folio for processing
class CancelAeonAppointmentJob < ApplicationJob
  queue_as :default

  def perform(appointment)
    appointment.requests.each do |request|
      move_request_to_draft(request)
    end
    aeon_client.cancel_appointment(appointment.id)
  end

  # When an appointment is cancelled, Aeon cancels the requests by default. We want to move them to draft
  # and dis-associated the appointment instead.
  def move_request_to_draft(request)
    Aeon::UpdateRequestService.new(request, { appointment_id: nil }, aeon_client:).call
  end

  def aeon_client
    @aeon_client ||= AeonClient.new
  end
end
