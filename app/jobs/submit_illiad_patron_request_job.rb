# frozen_string_literal: true

##
# Rails Job to submit a request to ILLiad for handling (and possible rerouting)
class SubmitIlliadPatronRequestJob < ApplicationJob
  queue_as :default
  retry_on Faraday::ConnectionFailed

  def perform(patron_request)
    response = IlliadRequest.new(patron_request.illiad_request_params(patron_request.selected_items.first)).request!

    if response.success?
      illiad_response_data = JSON.parse(response.body).select { |_, value| value.present? } || {}
      patron_request.update(illiad_response_data:)
      patron_request.notify_ilb! if illiad_response_data['Message'].present?
    else
      patron_request.notify_ilb!
    end
  end
end
