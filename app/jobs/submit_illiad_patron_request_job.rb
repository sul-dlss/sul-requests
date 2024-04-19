# frozen_string_literal: true

##
# Rails Job to submit a request to ILLiad for handling (and possible rerouting)
class SubmitIlliadPatronRequestJob < ApplicationJob
  queue_as :default
  retry_on Faraday::ConnectionFailed

  # rubocop:disable Metrics/AbcSize
  def perform(patron_request, item_id)
    item = patron_request.selected_items.find { |x| x.id == item_id }
    return unless item

    response = IlliadRequest.new(patron_request.illiad_request_params(item)).request!

    if response.success?
      illiad_response_data = JSON.parse(response.body).select { |_, value| value.present? } || {}
      patron_request.notify_ilb! if illiad_response_data['Message'].present?

      illiad_response_data
    else
      patron_request.notify_ilb!
      nil
    end
  end
  # rubocop:enable Metrics/AbcSize
end
