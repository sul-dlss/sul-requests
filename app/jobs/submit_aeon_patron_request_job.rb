# frozen_string_literal: true

##
# Rails Job to submit a request to ILLiad for handling (and possible rerouting)
class SubmitAeonPatronRequestJob < ApplicationJob
  queue_as :default
  retry_on Faraday::ConnectionFailed

  def perform(patron_request)
    aeon_requests = patron_request.aeon_requests
    username = patron_request.patron.email

    aeon_requests.each do |aeon_request|
      submit_aeon_request(username, aeon_request)
    end
  end

  # rubocop:disable Metrics/MethodLength
  # Once reading room logic for appointments is implemented, this mapping
  # should also contain scheduledDate, appointment id, appointment,
  # and reading room id. 
  def map_json(username, aeon_request)
    {
      callNumber: aeon_request.call_number,
      documentType: aeon_request.document_type,
      format: aeon_request.format,
      itemAuthor: aeon_request.author,
      itemDate: aeon_request.date,
      itemTitle: aeon_request.title,
      location: aeon_request.location,
      webRequestForm: 'GenericRequestMonograph',
      username: username,
      creationDate: Time.now.utc.iso8601,
      systemID: 'sul-requests',
      itemInfo1: aeon_request.item_url,
      specialRequest: aeon_request.special_request,
      site: aeon_request.site,
      shippingOption: aeon_request.shipping_option,
      itemInfo5: aeon_request.pages,
      forPublication: aeon_request.publication,
      itemNumber: aeon_request.item_number
    }.compact.to_json
  end
  # rubocop:enable Metrics/MethodLength

  def submit_aeon_request(username, aeon_request)
    aeon_payload = map_json(username, aeon_request)

    AeonClient.new.submit_searchworks_request(aeon_payload)
  end
end
