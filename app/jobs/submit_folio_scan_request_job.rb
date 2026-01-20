# frozen_string_literal: true

##
# Rails Job to submit a hold request to Folio for processing
class SubmitFolioScanRequestJob < SubmitFolioPatronRequestJob
  queue_as :default

  private

  def folio_request_data_for_item(request, item)
    FolioClient::CirculationRequestData.new(
      request_level: 'Item', request_type: 'Page',
      instance_id: item.instance&.id || request.instance_id, item_id: item.id, holdings_record_id: item.holdings_record_id,
      requester_id: scan_pseudopatron_id(request),
      proxy_user_id: nil, fulfillment_preference: 'Hold Shelf',
      pickup_service_point_id: pickup_service_point(request).id,
      patron_comments: patron_comments(request, item),
      request_expiration_date: expiration_date(request)
    )
  end

  def scan_pseudopatron_id(request)
    request.scan_service_point&.pseudopatron_barcode || Settings.scan_destinations.default.pseudopatron_barcode
  end

  def pickup_service_point(request)
    service_point_code = request.scan_service_point_code || Settings.scan_destinations.default.service_point_code
    Folio::Types.service_points.find_by(code: service_point_code)
  end
end
