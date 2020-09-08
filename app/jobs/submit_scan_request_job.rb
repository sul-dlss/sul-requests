# frozen_string_literal: true

##
# Rails Job to submit a Scan request to Symphony for processing
class SubmitScanRequestJob < ApplicationJob
  queue_as :default
  retry_on Faraday::ConnectionFailed

  def perform(scan)
    response = IlliadRequest.new(scan).request!

    scan.update(illiad_response_data: JSON.parse(response.body) || {})

    scan.send_to_symphony_later!
  end
end
