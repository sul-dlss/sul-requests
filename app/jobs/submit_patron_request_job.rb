# frozen_string_literal: true

##
# Rails Job that delegates requested items to ILLiad or Folio for processing
class SubmitPatronRequestJob < ApplicationJob
  queue_as :default

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def perform(patron_request)
    return convert_to_mediated_page(patron_request) if patron_request.mediateable?
    return place_title_hold(patron_request) if patron_request.barcodes.blank?

    ilb_items, folio_items = patron_request.selected_items.partition do |item|
      send_to_illiad?(patron_request, item)
    end

    illiad_response_data = ilb_items.each_with_object({}) do |item, responses|
      responses[item.id] = SubmitIlliadPatronRequestJob.perform_now(patron_request, item.id)
    end

    folio_responses = folio_items.each_with_object({}) do |item, responses|
      responses[item.id] = SubmitFolioPatronRequestJob.perform_now(patron_request, item.id)
    end

    patron_request.update(illiad_response_data:, folio_responses:)

    PatronRequestMailer.confirmation_email(patron_request).deliver_later
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  private

  # Conditions under which an item should be requested via ILLiad
  # The request is a scan, OR
  #   The patron is ILB eligible, AND
  #   The request is a recall, AND
  #   The item can be recalled, AND
  #     The item has a status indicating it won't be available soon, OR
  #     The item has an existing request queue
  def send_to_illiad?(patron_request, item) # rubocop:disable Metrics/CyclomaticComplexity
    return true if patron_request.scan?
    return false unless patron_request.patron&.ilb_eligible?
    return true if item.status == Folio::Item::STATUS_AGED_TO_LOST
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
    MediatedPage.create!(
      needed_date: patron_request.needed_date,
      origin: patron_request.origin_library_code,
      destination: patron_request.service_point_code,
      origin_location: patron_request.origin_location_code,
      item_id: patron_request.instance_hrid,
      user: patron_request.patron.user,
      item_title: patron_request.item_title,
      barcodes: patron_request.barcodes,
      estimated_delivery: patron_request.estimated_delivery
    )
  end

  def place_title_hold(patron_request)
    hold_request_data = FolioClient::HoldRequestData.new(pickup_location_id: patron_request.pickup_service_point.id,
                                                         patron_comments: patron_request.request_comments,
                                                         expiration_date: patron_request.needed_date.to_time.utc.iso8601)
    # Use instance_id instead of instance_hrid b/c the former is what is required, the latter will leave off the "a" at the beginning
    folio_response = folio_client.create_instance_hold(patron_request.patron.id, patron_request.instance_id, hold_request_data)

    patron_request.update(folio_responses: [folio_response])
  end

  def folio_client
    @folio_client ||= FolioClient.new
  end
end
