# frozen_string_literal: true

##
# Rails Job to submit a request to ILLiad for handling (and possible rerouting)
class SubmitIlliadRequestJob < ApplicationJob
  queue_as :default
  retry_on Faraday::ConnectionFailed
  discard_on ActiveRecord::RecordNotFound do |job, _error|
    Honeybadger.notify(
      "Attempted to send Request with ID #{job.request_id} to ILLiad, but no such Request was found."
    )
  end

  def perform(request_id)
    request = Request.find(request_id)
    response = IlliadRequest.new(request).request!

    if response.success?
      request.update(illiad_response_data: JSON.parse(response.body).select { |_, value| value.present? } || {})
      request.notify_ilb! if request.illiad_error?
    else
      request.notify_ilb!
    end
  end
end
