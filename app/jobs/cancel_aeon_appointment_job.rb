# frozen_string_literal: true

##
# Rails Job to submit a hold request to Folio for processing
class CancelAeonAppointmentJob < ApplicationJob
  queue_as :default

  def perform(appointment, cancel_requests: false)
    status = request_status(cancel_requests)
    appointment.requests.each do |request|
      move_request_to_saved_for_later(request, status:)
    end
    aeon_client.cancel_appointment(appointment)
  end

  def request_status(cancel)
    return Settings.aeon.queue_names.saved_for_later.transaction.first unless cancel

    Settings.aeon.queue_names.cancelled.by_user.transaction
  end

  # When an appointment is cancelled, Aeon cancels the requests by default. We want to move them to
  # saved for later and dis-associated the appointment instead.
  def move_request_to_saved_for_later(request, status:)
    Aeon::UpdateRequestService.new(request, { appointment_id: nil, status: }, aeon_client:).call
  end

  delegate :aeon_client, to: :Current
end
