# frozen_string_literal: true

##
# Rails Job to submit a hold request to Folio for processing
class SubmitFolioPatronRequestJob < ApplicationJob
  queue_as :default

  # we pass the ActiveRecord identifier to our job, rather than the ActiveRecord reference.
  #   This is recommended as a Sidekiq best practice (https://github.com/mperham/sidekiq/wiki/Best-Practices).
  #   It also helps reduce the size of the Redis database (used by Sidekiq), which stores its data in memory.
  def perform(request_id)
    request = find_request(request_id)

    return true unless request

    folio_request_data = generate_folio_request_data(request)

    folio_responses = submit_folio_requests!(folio_request_data)

    request.update(folio_request_data:, folio_responses:)
  end

  private

  def find_request(request_id)
    PatronRequest.find(request_id)
  rescue ActiveRecord::RecordNotFound
    Honeybadger.notify('Unable to find PatronRequest', context: { request_id: })
  end

  def best_request_type(patron, item)
    return 'Recall' if item.recallable?(patron)
    return 'Hold' if item.holdable?(patron)
    return 'Page' if item.pageable?(patron)

    'Hold'
  end

  def submit_folio_requests!(folio_request_data)
    folio_request_data.map do |item_request|
      response = folio_client.create_circulation_request(item_request)

      { id: item_request.item_id, response: }
    rescue FolioClient::Error => e
      Honeybadger.notify(e, error_message: "Circulation item request failed for item #{item_request.item_id} with #{e}")
      { id: item_request.item_id, errors: e.errors }
    rescue StandardError => e
      Honeybadger.notify(e, error_message: "Circulation item request failed for item #{item_request.item_id} with #{e}")
      { id: item_request.item_id }
    end
  end

  def generate_folio_request_data(request)
    patron = Folio::Patron.find_by(patron_key: request.patron_id) if request&.patron_id

    request.selected_items.map do |item|
      folio_request_data_for_item(patron, request, item)
    end
  end

  def folio_request_data_for_item(patron, request, item)
    FolioClient::CirculationRequestData.new(
      request_level: 'Item', request_type: best_request_type(patron, item),
      instance_id: request.instance_id, item_id: item.id, holdings_record_id: item.holdings_record_id,
      requester_id: patron&.id, fulfillment_preference: 'Hold Shelf', pickup_service_point_id: request.pickup_service_point.id,
      patron_comments: '', request_expiration_date: (Time.zone.today + 3.years).to_time.utc.iso8601
    )
  end

  def folio_client
    @folio_client ||= FolioClient.new
  end
end
