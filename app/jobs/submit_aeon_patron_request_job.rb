# frozen_string_literal: true

##
# Rails Job to submit a request to ILLiad for handling (and possible rerouting)
class SubmitAeonPatronRequestJob < ApplicationJob
  queue_as :default
  retry_on Faraday::ConnectionFailed

  def perform(patron_request)
    aeon_request = patron_request.aeon_request
    username = patron_request.patron.email
    submit_aeon_request(username, aeon_request)
  end

  def map_json(username, aeon_request) 
    {
      "callNumber": aeon_request.call_number,
      "documentType": aeon_request.document_type,
      "format": aeon_request.format,
      "itemAuthor": aeon_request.author,
      "itemDate": aeon_request.date,
      "itemTitle": aeon_request.title,
      "location": aeon_request.location,
      "scheduledDate": "2026-02-20T20:35:38.200Z",
      "webRequestForm": "GenericRequestMonograph",
      "username": username,
      "creationDate": "2026-02-17T20:35:38.200Z",
      "systemID": "sul-requests",
      "itemInfo1": aeon_request.aeon_link,
      "specialRequest": aeon_request.special_request,
      "site": aeon_request.site
    }.compact.to_json
  end

  def submit_aeon_request(username, aeon_request)
    aeon_payload = map_json(username, aeon_request)

    AeonClient.new.submit_searchworks_request(aeon_payload)
  end
end
