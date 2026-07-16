# frozen_string_literal: true

##
# Rails Job to submit a request to ILLiad for handling (and possible rerouting)
class SubmitAeonPatronRequestJob < ApplicationJob
  # Raised when one or more items in a patron request fail to submit to Aeon.
  class SubmissionFailure < StandardError
    def initialize(patron_request, count)
      @patron_request_id = patron_request.id
      @count = count
      super("Failed to create #{count} Aeon request(s) for patron_request #{patron_request.id}")
    end

    def to_honeybadger_context
      { patron_request_id: @patron_request_id, aeon_api_error_count: @count }
    end
  end

  queue_as :default
  retry_on Faraday::ConnectionFailed

  def perform(patron_request)
    return unless patron_request.aeon_page?

    if patron_request.request_type == 'activity'
      perform_activity_request(patron_request)
    elsif patron_request.ead_url.present?
      perform_ead_request(patron_request)
    else
      perform_folio_request(patron_request)
    end

    patron_request.update(submitted_to_aeon_at: Time.current)
  end

  # TODO: use the activity_ids from the patron_request_item.
  def perform_activity_request(patron_request)
    Array(patron_request.data['activity_ids']).each do |activity_id|
      if patron_request.ead_url.present?
        perform_ead_request(patron_request, activity_id:)
      else
        perform_folio_request(patron_request, activity_id:)
      end
    end
  end

  def perform_folio_request(patron_request, activity_id: nil)
    failures = []
    patron_request.patron_request_items.each do |requested_item|
      request = as_aeon_create_request_data(patron_request, requested_item, activity_id)
      record_aeon_response(patron_request, requested_item.item_id, request) { submit_aeon_request(request) }
    rescue AeonClient::ApiError => e
      failures << e
    end
    report_failures(patron_request, failures)
  end

  def perform_ead_request(patron_request, activity_id: nil)
    failures = []
    patron_request.patron_request_items.each do |requested_item|
      request = as_aeon_create_ead_request_data(patron_request, requested_item, activity_id)
      item_id = "#{request.call_number} #{request.item_volume}"
      record_aeon_response(patron_request, item_id, request) { submit_aeon_request(request) }
    rescue AeonClient::ApiError => e
      failures << e
    end
    report_failures(patron_request, failures)
  end

  def common_aeon_data_from_patron_request(patron_request, item, activity_id) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    AeonClient::RequestData.with_defaults.with(
      appointment_id: (item.appointment_id.presence&.to_i unless item.request_type == 'scan'),
      document_type: patron_request.document_type,
      for_publication: (ActiveRecord::Type::Boolean.new.cast(item.for_publication) if item.request_type == 'scan'),
      item_author: patron_request.author,
      item_date: patron_request.date,
      item_info1: patron_request.view_url,
      item_info5: (item.requested_pages if item.request_type == 'scan'),
      item_title: patron_request.item_title,
      reference_number: patron_request.to_global_id.to_s,
      shipping_option: patron_request.request_type == 'scan' ? 'Electronic Delivery' : nil,
      site: patron_request.aeon_site,
      special_request: (if item.request_type == 'scan' || item.appointment_id.present?
                          item.additional_information
                        end) || (patron_request.aeon_reading_special if item.appointment_id.present?),
      username: patron_request.user.aeon.username,
      activity_id:
    )
  end

  def as_aeon_create_ead_request_data(patron_request, item, activity_id)
    common_aeon_data_from_patron_request(patron_request, item, activity_id).with(
      call_number: "#{patron_request.ead_doc.identifier} #{item.hierarchy&.first}",
      ead_number: patron_request.ead_doc.identifier,
      item_info4: patron_request.ead_doc.conditions_governing_access,
      item_volume: item.title,
      web_request_form: 'multiple'
    )
  end

  # Once reading room logic for appointments is implemented, this mapping
  # should also contain scheduledDate, appointment id, appointment,
  # and reading room id.
  def as_aeon_create_request_data(patron_request, item, activity_id)
    common_aeon_data_from_patron_request(patron_request, item, activity_id).with(
      call_number: item.item_callnumber,
      item_number: item.barcode,
      location: item.origin_location_code || patron_request.origin_location_code,
      web_request_form: patron_request.selectable_items.many? ? 'multiple' : 'single'
    )
  end

  def submit_aeon_request(aeon_payload)
    created_request = aeon_client.create_request(aeon_payload)

    return created_request if created_request.valid?

    aeon_client.update_request_route(transaction_number: created_request.transaction_number,
                                     status: Settings.aeon.queue_names.saved_for_later.transaction.first)
  end

  delegate :aeon_client, to: :Current

  private

  def record_aeon_response(patron_request, item_id, request)
    response_data = yield.as_json
    write_aeon_response(patron_request, item_id, request, response_data)
  rescue AeonClient::ApiError => e
    write_aeon_response(patron_request, item_id, request, e.to_honeybadger_context)
    raise
  end

  def write_aeon_response(patron_request, item_id, request, response_data)
    patron_request.aeon_api_responses.where(item_id: item_id).delete_all
    patron_request.aeon_api_responses.create(item_id: item_id, request_data: request.as_json, response_data: response_data)
  end

  def report_failures(patron_request, failures)
    return if failures.empty?

    failures.each { |failure| Honeybadger.notify(failure) }
    raise SubmissionFailure.new(patron_request, failures.size)
  end
end
