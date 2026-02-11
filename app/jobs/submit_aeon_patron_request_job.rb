# frozen_string_literal: true

##
# Rails Job to submit a request to ILLiad for handling (and possible rerouting)
class SubmitAeonPatronRequestJob < ApplicationJob
  queue_as :default
  retry_on Faraday::ConnectionFailed

  def perform(patron_request)
    aeon_request = patron_request.aeon_request
  end

  # def notify_ilb(patron_request, aeon_response = nil)
  #  IlbMailer.failed_ilb_notification(patron_request, aeon_response).deliver_later
  # end
end
