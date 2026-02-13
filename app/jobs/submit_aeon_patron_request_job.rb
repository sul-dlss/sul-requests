# frozen_string_literal: true

##
# Rails Job to submit a request to ILLiad for handling (and possible rerouting)
class SubmitAeonPatronRequestJob < ApplicationJob
  queue_as :default
  retry_on Faraday::ConnectionFailed

  def perform(patron_request)
    puts patron_request.inspect
    aeon_request = patron_request.aeon_request
    username = patron_request.patron.username
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
      "scheduledDate": "2026-02-18T20:35:38.200Z",
      "webRequestForm": "GenericRequestMonograph",
      "username": username,
      "creationDate": "2026-02-11T20:35:38.200Z",
      "systemID": "sul-requests",
      "itemInfo1": aeon_request.aeon_link,
      "specialRequest": aeon_request.special_request,
      "site": aeon_request.site
    }.compact.to_json
  end

  def submit_aeon_request(username, aeon_request)
    puts "display submit json"
    aeon_payload = map_json(username, aeon_request)
    puts aeon_payload.to_s
  end

  # def notify_ilb(patron_request, aeon_response = nil)
  #  IlbMailer.failed_ilb_notification(patron_request, aeon_response).deliver_later
  # end
end
