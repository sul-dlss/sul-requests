# frozen_string_literal: true

##
# Rails Job to submit a request to ILLiad for handling (and possible rerouting)
class SubmitAeonPatronRequestJob < ApplicationJob
  queue_as :default
  retry_on Faraday::ConnectionFailed

  def perform(patron_request)
    return unless patron_request.aeon_page?

    patron_request.selected_items.each do |item|
      submit_aeon_request(as_aeon_create_request_data(patron_request, item))
    end
  end

  # rubocop:disable Metrics/MethodLength
  # Once reading room logic for appointments is implemented, this mapping
  # should also contain scheduledDate, appointment id, appointment,
  # and reading room id.
  def as_aeon_create_request_data(patron_request, item) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    callnumber = item.callnumber

    AeonClient::CreateRequestData.with_defaults.with(
      call_number: callnumber,
      document_type: 'Monograph',
      format: nil,
      item_author: patron_request.bib_data&.author,
      item_date: patron_request.bib_data&.pub_date,
      item_title: patron_request.bib_data&.title,
      location: patron_request.origin_location_code,
      web_request_form: 'GenericRequestMonograph',
      username: patron_request.user.aeon.username,
      item_info1: patron_request.bib_data&.view_url,
      special_request: patron_request.aeon_item&.dig(callnumber, 'additional_information') || patron_request.aeon_reading_special,
      site: patron_request.aeon_site,
      shipping_option: patron_request.aeon_digitization? ? 'Electronic Delivery' : nil,
      item_info5: patron_request.aeon_item&.dig(callnumber, 'requested_pages'),
      for_publication: patron_request.aeon_item&.dig(callnumber, 'for_publication') == 'Yes',
      item_number: item.barcode
    )
  end
  # rubocop:enable Metrics/MethodLength

  def submit_aeon_request(aeon_payload)
    AeonClient.new.create_request(aeon_payload)
  end
end
