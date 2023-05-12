# frozen_string_literal: true

##
# Rails Job to submit a Scan request to Symphony for processing
class SubmitScanRequestJob < ApplicationJob
  queue_as :default
  retry_on Faraday::ConnectionFailed

  def perform(scan)
    response = IlliadRequest.new(scan).request!

    scan.update(illiad_response_data: JSON.parse(response.body).select { |_, value| value.present? } || {})

    scan.notify_ilb! if scan.illiad_error?

    scan.send_to_ils_later!
  end
end
