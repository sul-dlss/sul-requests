# frozen_string_literal: true

## PlaceCdlHoldJob
class PlaceCdlHoldJob < ApplicationJob
  # rubocop:disable Metrics/MethodLength
  def perform(request, recall_status: 'NO')
    request.barcodes.each do |barcode|
      catalog_info = CatalogInfo.find(barcode)
      next unless catalog_info.home_location == 'CDL'

      symphony_client.place_hold(
        comment: "CDLREENTRANT;;;;;#{catalog_info.callkey}",
        fill_by_date: DateTime.now + 1.year,
        patron_barcode: Settings.cdl.pseudo_patron_id,
        item: {
          itemBarcode: barcode,
          holdType: 'COPY'
        },
        recall_status: recall_status,
        key: 'SUL'
      )
    end
  end
  # rubocop:enable Metrics/MethodLength

  def symphony_client
    @symphony_client ||= SymphonyClient.instance
  end
end
