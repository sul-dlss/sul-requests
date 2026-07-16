class CreatePatronRequestItems < ActiveRecord::Migration[8.1]
  def change
    create_table :patron_request_items do |t|
      t.references :patron_request, null: false, foreign_key: true
      t.string :item_id
      t.string :instance_id

      t.string :status
      t.string :request_type
      t.date :needed_date

      t.string :service_point_code
      t.string :item_callnumber
      t.string :origin_location_code

      t.text :data, limit: 1.gigabyte - 1.byte

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        # reload tables to ensure the new table is available for the model
        PatronRequest.reset_column_information
        PatronRequestItem.reset_column_information

        # populate the new table with data from the existing table
        PatronRequest.includes(:patron_request_items).find_each do |request|
          create_patron_request_items!(request)
        end
      end
    end
  end

  def create_patron_request_items!(request) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    return if request.patron_request_items.any?

    aeon_item_params = [:title, :hierarchy, :for_publication, :requested_pages, :additional_information, :appointment_id]

    if request.ead_url.present?
      request.data.dig('aeon_item')&.each_value do |item|
        request.patron_request_items.build(
          item_id: item['id'],
          request_type: request.request_type,
          additional_information: request.data.dig('aeon_reading_special'),
          activity_ids: request.data.dig('activity_ids'),
          ead_url: request.ead_url,
          **item.slice(*aeon_item_params)
        )
      end
    elsif request.folio_instance.present? && request.barcodes&.compact_blank.present?
      sleep 1 # rate limit FOLIO API requests
      request.data.dig('barcodes').compact_blank.each do |barcode_or_item_id|
        folio_item = request.folio_instance.items.find { |item| item.barcode == barcode_or_item_id || item.id == barcode_or_item_id }

        request.patron_request_items.build(
          item_id: folio_item&.id || barcode_or_item_id,
          item_callnumber: folio_item&.callnumber,
          barcode: folio_item&.barcode,
          origin_location_code: folio_item&.effective_location&.code,
          service_point_code: request.pickup_service_point&.code,
          instance_id: request.instance_id,
          scan_authors: request.data.dig('scan_authors').presence,
          scan_title: request.data.dig('scan_title').presence,
          scan_page_range: request.data.dig('scan_page_range').presence,
          request_type: request.request_type,
          estimated_delivery: request.data.dig('estimated_delivery'),
          activity_ids: request.data.dig('activity_ids'),
          additional_information: request.data.dig('aeon_reading_special'),
          mediation_data: (request.data.dig('item_mediation_data', folio_item.id) if folio_item),
          **((request.data.dig('aeon_item') || {})[folio_item.id]&.slice(*aeon_item_params) if folio_item)
        )
      end

      request.save
    end
  end
end
