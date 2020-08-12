# frozen_string_literal: true

##
# Rails Job to submit a Scan request to Symphony for processing
class SubmitScanRequestJob < ApplicationJob
  queue_as :default
  retry_on Faraday::ConnectionFailed

  def perform(scan)
    IlliadRequest.new(scan).request!

    scan.send_to_symphony_later!
  end
end
