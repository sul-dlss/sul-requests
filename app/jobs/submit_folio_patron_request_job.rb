# frozen_string_literal: true

##
# Rails Job to submit a hold request to Folio for processing
class SubmitFolioPatronRequestJob < ApplicationJob
  queue_as :default

  def perform(patron_request_item)
    return if patron_request_item.folio_item.blank?

    request_data = folio_request_data_for_item(patron_request_item)

    response = submit_folio_requests!(request_data)

    handle_folio_errors(response, patron_request_item) if response&.dig('errors')

    patron_request_item.folio_api_responses.create(request_data:, response_data: response)
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
    folio_client.create_circulation_request(item_request)
  rescue FolioClient::Error => e
    Honeybadger.notify(e, error_message: "Circulation item request failed for item #{item_request.item_id} with #{e}")
    e.errors
  rescue StandardError => e
    Honeybadger.notify(e, error_message: "Circulation item request failed for item #{item_request.item_id} with #{e}")
    {}
  end

  def folio_request_data_for_item(patron_request_item) # rubocop:disable Metrics/AbcSize
    request = patron_request_item.patron_request
    item = patron_request_item.folio_item

    FolioClient::CirculationRequestData.new(
      request_level: 'Item', request_type: best_request_type(request, item),
      instance_id: item.instance&.id || request.instance_id, item_id: item.id, holdings_record_id: item.holdings_record_id,
      requester_id: request.requester_patron_id, proxy_user_id: (if request.for_sponsor?
                                                                   request.patron&.id
                                                                 end), fulfillment_preference: 'Hold Shelf',
      pickup_service_point_id: request.pickup_service_point.id,
      patron_comments: patron_comments(request, item), request_expiration_date: expiration_date(request)
    )
  end

  def expiration_date(request)
    (request.needed_date || (Time.zone.today + 3.years)).to_time.utc.iso8601
  end

  def patron_comments(request, item)
    [request.request_comments,
     (if item.instance&.id && item.instance&.id != request.instance_id
        { bound_with_child_instance_id: request.instance_id }.to_json
      end)].compact.join("\n")
  end

  def folio_client
    @folio_client ||= FolioClient.new
  end

  def handle_folio_errors(response, patron_request_item)
    case # rubocop:disable Style/EmptyCaseCondition
    # Multiple pseudo-patron requests for the same item need staff to manually process the item
    when patron_request_item.patron&.id.nil? && response.dig('errors', 0,
                                                             'message') == 'This requester already has an open request for this item'
      MultipleHoldsMailer.multiple_holds_notification(patron_request_item).deliver_now
    end
  end
end
