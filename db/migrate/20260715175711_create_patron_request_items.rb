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
  end
end
