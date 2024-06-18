# frozen_string_literal: true

##
# Rails Job to submit a hold request to Folio for processing
class SubmitFolioPatronRequestJob < ApplicationJob
  queue_as :default

  def perform(request, item_id)
    item = request.selected_items.find { |x| x.id == item_id }
    return unless item

    request_data = folio_request_data_for_item(request, item)

    response = submit_folio_requests!(request_data)

    handle_folio_errors(response, request, item) if response['errors']

    response.merge(request_data:)
  end

  private

  def best_request_type(request, item)
    if (Settings.hold_instead_of_recall.include?(item.status) || request.fulfillment_type == 'hold') && item.holdable?(request.patron)
      return 'Hold'
    end
    return 'Recall' if item.recallable?(request.patron)
    return 'Hold' if item.holdable?(request.patron)
    return 'Page' if item.pageable?(request.patron)

    'Hold'
  end

  def submit_folio_requests!(item_request)
    response = folio_client.create_circulation_request(item_request)

    { response: }
  rescue FolioClient::Error => e
    Honeybadger.notify(e, error_message: "Circulation item request failed for item #{item_request.item_id} with #{e}")
    { errors: e.errors }
  rescue StandardError => e
    Honeybadger.notify(e, error_message: "Circulation item request failed for item #{item_request.item_id} with #{e}")
    {}
  end

  def folio_request_data_for_item(request, item) # rubocop:disable Metrics/AbcSize
    FolioClient::CirculationRequestData.new(
      request_level: 'Item', request_type: best_request_type(request, item),
      instance_id: request.instance_id, item_id: item.id, holdings_record_id: item.holdings_record_id,
      requester_id: request.requester_patron_id, proxy_user_id: (if request.for_sponsor?
                                                                   request.patron&.id
                                                                 end), fulfillment_preference: 'Hold Shelf',
      pickup_service_point_id: request.pickup_service_point.id,
      patron_comments: request.request_comments, request_expiration_date: (Time.zone.today + 3.years).to_time.utc.iso8601,
      # TODO: remove key/value after poppy launch
      poppy_request: folio_client.poppy?
    )
  end

  def folio_client
    @folio_client ||= FolioClient.new
  end

  def handle_folio_errors(response, request, item)
    case # rubocop:disable Style/EmptyCaseCondition
    # Multiple pseudo-patron requests for the same item need staff to manually process the item
    when request.patron&.id.nil? && response.dig('errors', 'errors', 0,
                                                 'message') == 'This requester already has an open request for this item'
      MultipleHoldsMailer.multiple_holds_notification(request, item).deliver_now
    end
  end
end
