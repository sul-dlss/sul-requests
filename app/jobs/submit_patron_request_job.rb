# frozen_string_literal: true

##
# Rails Job that delegates requested items to ILLiad or Folio for processing
class SubmitPatronRequestJob < ApplicationJob
  queue_as :default

  def perform(patron_request) # rubocop:disable Metrics/AbcSize
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
  end

  private

  # Conditions under which an item should be requested via ILLiad
  # The request is a scan, OR
  #   The patron is ILB eligible, AND
  #   The request is a recall, AND
  #   The item can be recalled, AND
  #     The item has a status indicating it won't be available soon, OR
  #     The item has an existing request queue (TODO: https://github.com/sul-dlss/sul-requests/issues/2234)
  def send_to_illiad?(patron_request, item)
    return true if patron_request.scan?
    return false unless patron_request.patron.ilb_eligible?
    return false if item.status.in?(folio_recall_statuses)

    patron_request.fulfillment_type == 'recall' &&
      item.hold_recallable?(patron_request.patron)
  end

  # If an item has one of these statuses it's OK to request it via FOLIO;
  # otherwise, try ILLiad first for a faster delivery
  def folio_recall_statuses
    [
      Folio::Item::STATUS_IN_PROCESS,
      Folio::Item::STATUS_ON_ORDER,
      Folio::Item::STATUS_IN_TRANSIT
    ].freeze
  end
end
