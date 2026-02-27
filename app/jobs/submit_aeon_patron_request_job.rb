# frozen_string_literal: true

##
# Rails Job to submit a request to ILLiad for handling (and possible rerouting)
class SubmitAeonPatronRequestJob < ApplicationJob
  queue_as :default
  retry_on Faraday::ConnectionFailed

  def perform(patron_request)
    aeon_requests = patron_request.aeon_requests

    aeon_requests.each do |aeon_request|
      submit_aeon_request(as_aeon_create_request_data(aeon_request))
    end
  end

  # rubocop:disable Metrics/MethodLength
  # Once reading room logic for appointments is implemented, this mapping
  # should also contain scheduledDate, appointment id, appointment,
  # and reading room id.
  def as_aeon_create_request_data(aeon_request)
    AeonClient::CreateRequestData.with_defaults.with(
      call_number: aeon_request.call_number,
      document_type: aeon_request.document_type,
      format: aeon_request.format,
      item_author: aeon_request.author,
      item_date: aeon_request.date,
      item_title: aeon_request.title,
      location: aeon_request.location,
      web_request_form: 'GenericRequestMonograph',
      username: aeon_request.username,
      item_info1: aeon_request.item_url,
      special_request: aeon_request.special_request,
      site: aeon_request.site,
      shipping_option: aeon_request.shipping_option,
      item_info5: aeon_request.pages,
      for_publication: aeon_request.publication,
      item_number: aeon_request.item_number
    )
  end
  # rubocop:enable Metrics/MethodLength

  def submit_aeon_request(aeon_payload)
    AeonClient.new.create_request(aeon_payload)
  end
end
