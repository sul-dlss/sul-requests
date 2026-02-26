# frozen_string_literal: true

##
# Rails Job that delegates requested items to ILLiad or Folio for processing
class SubmitPatronRequestJob < ApplicationJob
  queue_as :default

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def perform(patron_request)
    return convert_to_mediated_page(patron_request) if patron_request.mediateable?
    return place_title_hold(patron_request) if patron_request.barcodes.blank?
    return perform_scan_request(patron_request) if patron_request.scan?

    ilb_items, folio_items = patron_request.selected_items.partition do |item|
      send_to_illiad?(patron_request, item)
    end

    ilb_items.each do |item|
      next if patron_request.illiad_api_responses.any? { |r| r.item_id == item.id && r.response_data }

      SubmitIlliadPatronRequestJob.perform_now(patron_request, item.id)
    end

    folio_items.each do |item|
      next if patron_request.folio_api_responses.any? { |r| r.item_id == item.id && r.response_data&.dig('status') }

      SubmitFolioPatronRequestJob.perform_now(patron_request, item.id)
    end

    PatronRequestMailer.confirmation_email(patron_request)&.deliver_later
  end

  def perform_scan_request(patron_request)
    ilb_items, scan_email_items = patron_request.selected_items.partition do |_item|
      patron_request.scan_service_point&.ilb
    end

    folio_items = patron_request.selected_items.select do |_item|
      patron_request.scan_service_point&.pseudopatron_barcode.present?
    end

    ilb_items.each do |item|
      next if patron_request.illiad_api_responses.any? { |r| r.item_id == item.id && r.response_data }

      SubmitIlliadPatronRequestJob.perform_now(patron_request, item.id)
    end

    _email_response_data = scan_email_items.each do |item|
      PatronRequestMailer.staff_scan_email(patron_request, item.id)&.deliver_later
    end

    folio_items.each do |item|
      next if patron_request.folio_api_responses.any? { |r| r.item_id == item.id && r.response_data&.dig('status') }

      SubmitFolioScanRequestJob.perform_now(patron_request, item.id)
    end

    PatronRequestMailer.confirmation_email(patron_request)&.deliver_later
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  private

  # Conditions under which an item should be requested via ILLiad
  # The request is a scan, OR
  #   The patron is ILB eligible, AND
  #   The request is a recall, AND
  #   The item can be recalled, AND
  #     The item has a status indicating it won't be available soon, OR
  #     The item has an existing request queue
  def send_to_illiad?(patron_request, item) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    return true if patron_request.scan?
    return false unless patron_request.patron&.ilb_eligible?
    return true if item.status == Folio::Item::STATUS_AGED_TO_LOST || item.illiad_preferred?
    return false unless patron_request.fulfillment_type == 'recall'
    return false unless item.hold_recallable?(patron_request.patron)

    item.status.in?(illiad_recall_statuses) || item.queue_length.positive?
  end

  # If an item has one of these statuses the patron won't get it anytime soon
  # from FOLIO, so try ILLiad
  def illiad_recall_statuses
    [
      Folio::Item::STATUS_CHECKED_OUT,
      Folio::Item::STATUS_MISSING,
      Folio::Item::STATUS_AGED_TO_LOST,
      Folio::Item::STATUS_CLAIMED_RETURNED,
      Folio::Item::STATUS_DECLARED_LOST,
      Folio::Item::STATUS_LONG_MISSING,
      Folio::Item::STATUS_LOST_AND_PAID,
      Folio::Item::STATUS_PAGED
    ].freeze
  end

  def convert_to_mediated_page(patron_request)
    patron_request.notify_mediator!
    PatronRequestMailer.confirmation_email(patron_request).deliver_later
  end

  def place_title_hold(patron_request) # rubocop:disable Metrics/AbcSize
    hold_request_data = FolioClient::HoldRequestData.new(pickup_location_id: patron_request.pickup_service_point.id,
                                                         patron_comments: patron_request.request_comments,
                                                         expiration_date: patron_request.needed_date.to_time.utc.iso8601)

    folio_response = folio_client.create_instance_hold(patron_request.patron.id, patron_request.instance_id, hold_request_data)

    patron_request.folio_api_responses.where(item_id: nil).delete_all
    patron_request.folio_api_responses.create(item_id: nil, request_data: hold_request_data.to_h, response_data: folio_response)
    PatronRequestMailer.confirmation_email(patron_request).deliver_later
  end

  def folio_client
    @folio_client ||= FolioClient.new
  end
end
