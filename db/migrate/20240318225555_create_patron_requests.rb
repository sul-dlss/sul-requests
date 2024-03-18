class CreatePatronRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :patron_requests do |t|
      t.string :patron_id
      t.string :patron_email
      t.string :instance_hrid
      t.date :needed_date
      t.string :service_point_code
      t.text :data
      t.string :fulfillment_type
      t.string :status
      t.string :folio_request_id
      t.string :origin_location_code

      t.timestamps
    end
    add_index :patron_requests, :patron_id
    add_index :patron_requests, :instance_hrid
    add_index :patron_requests, :folio_request_id
    add_index :patron_requests, :origin_location_code
  end
end
