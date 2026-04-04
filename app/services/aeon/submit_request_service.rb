# frozen_string_literal: true

module Aeon
  # Build and submit Aeon requests for a PatronRequest.
  # Handles both FOLIO item and EAD item flows.
  class SubmitRequestService
    attr_reader :patron_request, :aeon_client

    def initialize(patron_request, aeon_client: AeonClient.new)
      @patron_request = patron_request
      @aeon_client = aeon_client
    end

    def call
      return unless patron_request.aeon_page?
      return submit_ead_requests if patron_request.ead_url.present?

      submit_folio_requests
    end

    private

    def submit_folio_requests
      patron_request.selected_items.map do |folio_item|
        volume_params = patron_request.aeon_item&.dig(folio_item.id) || {}
        payload = build_folio_payload(folio_item, volume_params)
        response = submit(payload)

        store_response(folio_item.id, payload, response)
        { item_id: folio_item.id, response: }
      end
    end

    def submit_ead_requests
      patron_request.aeon_item.map do |barcode_id, volume_params|
        payload = build_ead_payload(volume_params)
        response = submit(payload)

        item_id = "#{payload.call_number} #{payload.item_volume}"
        store_response(item_id, payload, response)
        { item_id: barcode_id, response: }
      end
    end

    def build_common_payload(volume_params) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      AeonClient::RequestData.with_defaults.with(
        appointment_id: volume_params['appointment_id'].presence&.to_i,
        document_type: patron_request.document_type,
        for_publication: ActiveRecord::Type::Boolean.new.cast(volume_params['for_publication']),
        item_author: patron_request.author,
        item_date: patron_request.date,
        item_info1: patron_request.view_url,
        item_info5: volume_params['requested_pages'],
        item_title: patron_request.item_title,
        reference_number: patron_request.to_global_id.to_s,
        shipping_option: patron_request.request_type == 'scan' ? 'Electronic Delivery' : nil,
        site: patron_request.aeon_site,
        special_request: if patron_request.request_type == 'scan'
                           volume_params['additional_information']
                         else
                           patron_request.aeon_reading_special
                         end,
        username: patron_request.user.aeon.username
      )
    end

    def build_folio_payload(folio_item, volume_params)
      build_common_payload(volume_params).with(
        call_number: folio_item.callnumber,
        item_number: folio_item.barcode,
        location: patron_request.origin_location_code,
        web_request_form: patron_request.selectable_items.many? ? 'multiple' : 'single'
      )
    end

    def build_ead_payload(volume_params)
      build_common_payload(volume_params).with(
        call_number: "#{patron_request.ead_doc.identifier} #{volume_params['hierarchy']&.first}",
        ead_number: patron_request.ead_doc.identifier,
        item_info4: patron_request.ead_doc.conditions_governing_access,
        item_volume: volume_params['title'],
        web_request_form: 'multiple'
      )
    end

    def submit(payload)
      created_request = aeon_client.create_request(payload)

      unless created_request.valid?
        aeon_client.update_request_route(transaction_number: created_request.transaction_number,
                                         status: Settings.aeon.queue_names.draft.transaction.first)
      end

      created_request
    end

    def store_response(item_id, payload, response)
      patron_request.aeon_api_responses.where(item_id:).delete_all
      patron_request.aeon_api_responses.create(item_id:, request_data: payload.as_json, response_data: response.as_json)
    end
  end
end
