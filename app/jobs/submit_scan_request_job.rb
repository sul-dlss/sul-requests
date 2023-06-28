# frozen_string_literal: true

##
# Rails Job to submit a Scan request to the ILS for processing
class SubmitScanRequestJob < ApplicationJob
  queue_as :default
  retry_on Faraday::ConnectionFailed

  def perform(scan)
    response = IlliadRequest.new(scan).request!

    scan.update(illiad_response_data: JSON.parse(response.body).select { |_, value| value.present? } || {})

    scan.notify_ilb! if scan.illiad_error?

    # This ensures that only scan rules with a destination get sent to the ILS.
    # We no longer want to send SAL3 requests to the ILS as this is handled by the ILLiad integration.
    # SAL1/2 requests still go to the ILS at this time.
    scan.send_to_ils_later! if scan.scan_destination.present?
  end
end
