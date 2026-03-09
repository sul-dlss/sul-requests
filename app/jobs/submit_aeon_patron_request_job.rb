# frozen_string_literal: true

##
# Rails Job to submit a request to ILLiad for handling (and possible rerouting)
class SubmitAeonPatronRequestJob < ApplicationJob
  queue_as :default
  retry_on Faraday::ConnectionFailed

  def perform(patron_request)
    return unless patron_request.aeon_page?

    patron_request.aeon_item.each do |id, volume_params|
      request = as_create_aeon_request_data(patron_request, id, volume_params)
      response = submit_aeon_request(request)

      update_patron_request_record(patron_request, request, response, id)
    end
  end

  def update_patron_request_record(patron_request, request, response, id)
    item_id = patron_request.ead_url.present? ? "#{request.call_number} #{request.item_volume}" : id
    patron_request.aeon_api_responses.where(item_id:).delete_all
    patron_request.aeon_api_responses.create(item_id:, request_data: request.as_json, response_data: response.as_json)
  end

  def as_create_aeon_request_data(patron_request, id, volume_params) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    instance_record = patron_request.folio_instance || patron_request.ead_doc
    request_data = AeonClient::RequestData.with_defaults.with(
      appointment_id: volume_params['appointment_id'].presence&.to_i,
      for_publication: volume_params['for_publication'] == 'yes',
      item_author: instance_record.author,
      item_date: instance_record.date,
      item_info1: patron_request.view_url,
      item_info5: volume_params['requested_pages'],
      item_title: patron_request.item_title,
      item_volume: volume_params['subseries'],
      location: patron_request.origin_location_code,
      reference_number: patron_request.to_global_id.to_s,
      shipping_option: patron_request.request_type == 'scan' ? 'Electronic Delivery' : nil,
      site: patron_request.aeon_site,
      special_request: volume_params['additional_information'] || patron_request.aeon_reading_special,
      username: patron_request.user.aeon.username,
      web_request_form: patron_request.aeon_web_request_form
    )
    if patron_request.ead_doc.present?
      ead_specific(request_data, instance_record,
                   volume_params)
    else
      folio_specific(request_data, id, patron_request)
    end
  end

  def folio_specific(request_data, id, patron_request)
    selected_item = patron_request.selected_items.find { |elem| elem.id == id }
    request_data.with(
      call_number: selected_item&.callnumber,
      item_number: selected_item&.barcode,
      document_type: 'Monograph'
    )
  end

  def ead_specific(request_data, ead_doc, volume_params)
    request_data.with(
      call_number: "#{ead_doc.identifier} #{volume_params['series']}".strip,
      ead_number: ead_doc.identifier
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
