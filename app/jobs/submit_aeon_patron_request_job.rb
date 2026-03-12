# frozen_string_literal: true

##
# Rails Job to submit a request to ILLiad for handling (and possible rerouting)
class SubmitAeonPatronRequestJob < ApplicationJob
  queue_as :default
  retry_on Faraday::ConnectionFailed

  def perform(patron_request) # rubocop:disable Metrics/AbcSize
    return unless patron_request.aeon_page?
    return perform_ead_request(patron_request) if patron_request.ead_url.present?

    patron_request.selected_items.each do |folio_item|
      request = as_aeon_create_request_data(patron_request, folio_item, patron_request.aeon_item&.dig(folio_item.id) || {})
      response = submit_aeon_request(request)

      patron_request.aeon_api_responses.where(item_id: folio_item.id).delete_all
      patron_request.aeon_api_responses.create(item_id: folio_item.id, request_data: request.as_json, response_data: response.as_json)
    end
  end

  def perform_ead_request(patron_request)
    patron_request.aeon_item.each_value do |volume_params|
      request = as_aeon_create_ead_request_data(patron_request, volume_params)
      response = submit_aeon_request(request)

      item_id = "#{request.call_number} #{request.item_volume}"

      patron_request.aeon_api_responses.where(item_id: item_id).delete_all
      patron_request.aeon_api_responses.create(item_id: item_id, request_data: request.as_json, response_data: response.as_json)
    end
  end

  def common_aeon_data_from_patron_request(patron_request, volume_params) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    AeonClient::RequestData.with_defaults.with(
      appointment_id: volume_params['appointment_id'].presence&.to_i,
      for_publication: volume_params['for_publication'] == 'yes',
      item_author: patron_request.author,
      item_date: patron_request.date,
      item_info1: patron_request.view_url,
      item_info5: volume_params['requested_pages'],
      item_title: patron_request.item_title,
      reference_number: patron_request.to_global_id.to_s,
      shipping_option: patron_request.request_type == 'scan' ? 'Electronic Delivery' : nil,
      site: patron_request.aeon_site,
      special_request: volume_params['additional_information'] || patron_request.aeon_reading_special,
      username: patron_request.user.aeon.username
    )
  end

  def as_aeon_create_ead_request_data(patron_request, volume_params)
    common_aeon_data_from_patron_request(patron_request, volume_params).with(
      call_number: "#{patron_request.ead_doc.identifier} #{volume_params['series']}",
      ead_number: patron_request.ead_doc.identifier,
      item_volume: volume_params['subseries'],
      web_request_form: 'multiple'
    )
  end

  # Once reading room logic for appointments is implemented, this mapping
  # should also contain scheduledDate, appointment id, appointment,
  # and reading room id.
  def as_aeon_create_request_data(patron_request, folio_item, volume_params)
    common_aeon_data_from_patron_request(patron_request, volume_params).with(
      call_number: folio_item.callnumber,
      document_type: 'Monograph',
      item_number: folio_item.barcode,
      location: patron_request.origin_location_code,
      web_request_form: patron_request.selectable_items.many? ? 'multiple' : 'single'
    )
  end

  def submit_aeon_request(aeon_payload)
    response = aeon_client.create_request(aeon_payload)

    return response if complete?(aeon_payload)

    aeon_client.update_request_route(transaction_number: response.transaction_number,
                                     status: Settings.aeon.queue_names.draft.transaction.first)
  end

  def aeon_client
    @aeon_client ||= AeonClient.new
  end

  def complete?(payload)
    if payload.shipping_option == 'Electronic Delivery'
      payload.item_info5.present?
    else
      payload.appointment_id.present?
    end
  end
end
