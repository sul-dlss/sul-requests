# frozen_string_literal: true

##
# Rails Job to submit a hold request to Folio for processing
class CancelAeonAppointmentJob < ApplicationJob
  queue_as :default

  def perform(appointment, cancel_requests: false)
    status = request_status(cancel_requests)
    appointment.requests.each do |request|
      move_request(request, status:)
    end
    aeon_client.cancel_appointment(appointment.id)
  end

  def request_status(cancel)
    return Settings.aeon.queue_names.draft.transaction.first unless cancel

    Settings.aeon.queue_names.cancelled.transaction.first
  end

  # When an appointment is cancelled, Aeon cancels the requests by default. We want to move them to draft
  # and dis-associated the appointment instead.
  def move_request(request, status:)
    aeon_client.update_request(request.transaction_number, AeonClient::DeleteAppointmentRequestData.new)
    aeon_client.update_request_route(transaction_number: request.transaction_number,
                                     status:)
  end

  def aeon_client
    @aeon_client ||= AeonClient.new
  end
end
