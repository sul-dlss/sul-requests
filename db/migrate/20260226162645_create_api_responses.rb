class CreateApiResponses < ActiveRecord::Migration[8.1]
  def change
    create_table :api_responses do |t|
      t.string :type
      t.string :item_id, index: true
      t.binary :request_data
      t.binary :response_data
      t.references :patron_request, null: false, foreign_key: true

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        PatronRequest.find_each do |patron_request|
          patron_request.folio_responses&.each do |item_id, folio_response|
            FolioApiResponse.create!(
              item_id: item_id,
              request_data: folio_response['request_data'],
              response_data: folio_response['response'] || folio_response['errors'] || folio_response.except('request_data')
            )
          end

          patron_request.illiad_response_data&.each do |item_id, illiad_response|
            IlliadApiResponse.create!(
              item_id: item_id,
              response_data: illiad_response
            )
          end
        end
      end
    end
  end
end
