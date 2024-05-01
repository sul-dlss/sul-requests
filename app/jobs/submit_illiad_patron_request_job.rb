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
      notify_ilb(patron_request, illiad_response_data) if illiad_response_data['Message'].present?

      illiad_response_data
    else
      notify_ilb(patron_request)
      nil
    end
  end
  # rubocop:enable Metrics/AbcSize

  private

  def notify_ilb(patron_request, illiad_response = nil)
    IlbMailer.failed_ilb_notification(patron_request, illiad_response).deliver_later
  end
end
