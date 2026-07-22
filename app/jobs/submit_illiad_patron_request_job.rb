# frozen_string_literal: true

##
# Rails Job to submit a request to ILLiad for handling (and possible rerouting)
class SubmitIlliadPatronRequestJob < ApplicationJob
  queue_as :default
  retry_on Faraday::ConnectionFailed

  def perform(patron_request_item)
    record_illiad_response(patron_request_item) do
      IlliadClient.new.create(patron_request_item.illiad_request_params)
    end
  end

  private

  def record_illiad_response(patron_request_item)
    record = yield
    patron_request_item.create_illiad_api_response(response_data: record.as_json)
    record
  rescue IlliadClient::ApiError => e
    patron_request_item.create_illiad_api_response(response_data: e.to_honeybadger_context)
    IlbMailer.failed_ilb_notification(patron_request_item, e.response.body).deliver_later
    nil
  end
end
