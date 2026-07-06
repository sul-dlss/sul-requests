# frozen_string_literal: true

##
# Rails Job to submit a request to ILLiad for handling (and possible rerouting)
class SubmitIlliadPatronRequestJob < ApplicationJob
  queue_as :default
  retry_on Faraday::ConnectionFailed

  def perform(patron_request, item_id)
    item = patron_request.selected_items.find { |x| x.id == item_id }
    return unless item

    record_illiad_response(patron_request, item_id) do
      IlliadClient.new.create(patron_request.illiad_request_params(item))
    end
  end

  private

  def record_illiad_response(patron_request, item_id)
    record = yield
    write_illiad_response(patron_request, item_id, record.as_json)
    record
  rescue IlliadClient::ApiError => e
    write_illiad_response(patron_request, item_id, e.to_honeybadger_context)
    IlbMailer.failed_ilb_notification(patron_request, e.response.body).deliver_later
    nil
  end

  def write_illiad_response(patron_request, item_id, response_data)
    patron_request.illiad_api_responses.where(item_id: item_id).delete_all
    patron_request.illiad_api_responses.create(item_id: item_id, response_data: response_data)
  end
end
