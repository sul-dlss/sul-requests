# frozen_string_literal: true

##
# Rails Job that delegates requested items to ILLiad or Folio for processing
class SubmitPatronRequestJob < ApplicationJob
  queue_as :default

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def perform(patron_request)
    return convert_to_mediated_page(patron_request) if patron_request.mediateable?
    return place_title_hold(patron_request) if patron_request.barcodes.blank?

    ilb_items, folio_items = patron_request.selected_items.partition do |item|
      send_to_illiad?(patron_request, item)
    end

    illiad_response_data = ilb_items.each_with_object({}) do |item, responses|
      next if patron_request.illiad_response_data&.dig(item.id)

      responses[item.id] = SubmitIlliadPatronRequestJob.perform_now(patron_request, item.id)
    end

    folio_responses = folio_items.each_with_object({}) do |item, responses|
      next if patron_request.folio_responses&.dig(item.id, 'response', 'status')

      responses[item.id] = SubmitFolioPatronRequestJob.perform_now(patron_request, item.id)
    end

    patron_request.update(illiad_response_data:, folio_responses:)

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
    return true if item.status == Folio::Item::STATUS_AGED_TO_LOST
    return false unless patron_request.fulfillment_type == 'recall'
    return false unless item.hold_recallable?(patron_request.patron)
    return true if item.illiad_preferred?

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

  def place_title_hold(patron_request)
    hold_request_data = FolioClient::HoldRequestData.new(pickup_location_id: patron_request.pickup_service_point.id,
                                                         patron_comments: patron_request.request_comments,
                                                         expiration_date: patron_request.needed_date.to_time.utc.iso8601)

    folio_response = folio_client.create_instance_hold(patron_request.patron.id, patron_request.instance_id, hold_request_data)

    patron_request.update(folio_responses: { nil => folio_response })
    PatronRequestMailer.confirmation_email(patron_request).deliver_later
  end

  def folio_client
    @folio_client ||= FolioClient.new
  end
end
