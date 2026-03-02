# frozen_string_literal: true

##
# Rails Job to submit a request to ILLiad for handling (and possible rerouting)
class SubmitAeonPatronRequestJob < ApplicationJob
  queue_as :default
  retry_on Faraday::ConnectionFailed

  def perform(patron_request)
    return unless patron_request.aeon_page?

    patron_request.selected_items.each do |item|
      request = as_aeon_create_request_data(patron_request, item)
      response = submit_aeon_request(request)

      patron_request.aeon_api_responses.where(item_id: nil).delete_all
      patron_request.aeon_api_responses.create(item_id: nil, request_data: request.as_json, response_data: response)
    end
  end

  # rubocop:disable Metrics/MethodLength
  # Once reading room logic for appointments is implemented, this mapping
  # should also contain scheduledDate, appointment id, appointment,
  # and reading room id.
  def as_aeon_create_request_data(patron_request, item) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity
    AeonClient::CreateRequestData.with_defaults.with(
      appointment_id: patron_request.aeon_item&.dig(item.id, 'appointment_id')&.to_i,
      call_number: item.callnumber,
      document_type: 'Monograph',
      format: nil,
      item_author: patron_request.bib_data&.author,
      item_date: patron_request.bib_data&.pub_date,
      item_title: patron_request.item_title,
      location: patron_request.origin_location_code,
      web_request_form: 'GenericRequestMonograph',
      username: patron_request.user.aeon.username,
      item_info1: patron_request.view_url,
      special_request: patron_request.aeon_item&.dig(item.id, 'additional_information') || patron_request.aeon_reading_special,
      site: patron_request.aeon_site,
      shipping_option: patron_request.aeon_digitization? ? 'Electronic Delivery' : nil,
      item_info5: patron_request.aeon_item&.dig(item.id, 'requested_pages'),
      for_publication: patron_request.aeon_item&.dig(item.id, 'for_publication') == 'Yes',
      item_number: item.barcode
    )
  end
  # rubocop:enable Metrics/MethodLength

  def submit_aeon_request(aeon_payload)
    AeonClient.new.create_request(aeon_payload)
  end
end
