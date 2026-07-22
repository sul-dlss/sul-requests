class AddPatronRequestItemIdToApiResponse < ActiveRecord::Migration[8.1]
  def change
    add_reference :api_responses, :patron_request_item, null: true, foreign_key: true

    reversible do |dir|
      dir.up do
        # reload tables to ensure the new table is available for the model
        PatronRequest.reset_column_information
        PatronRequestItem.reset_column_information

        # populate the new table with data from the existing table
        PatronRequest.includes(:patron_request_items, :folio_api_responses, :illiad_api_responses, :aeon_api_responses).find_each do |request|
          request.patron_request_items.find_each do |item|
            next if item.migrated_item_id_or_barcode.present? || item.item_id.blank?

            request.folio_api_responses.where(item_id: item.item_id).update_all(patron_request_item_id: item.id)
            request.illiad_api_responses.where(item_id: item.item_id).update_all(patron_request_item_id: item.id)
            request.aeon_api_responses.where(item_id: item.item_id).update_all(patron_request_item_id: item.id)
          end
        end
      end
    end
  end
end
