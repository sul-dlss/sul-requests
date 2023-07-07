class CreateFolioCommandLog < ActiveRecord::Migration[7.0]
  def change
    create_table :folio_command_logs do |t|
      # Storing these UUIDs as strings because Sqlite doesn't have a UUID type.
      t.string :pickup_location_id, null: false
      t.string :user_id, null: false
      t.string :barcode, null: false
      t.string :item_id, null: false
      t.string :patron_comments
      t.date :expiration_date, null: false
      t.references :request, null: false
      t.timestamps
    end
  end
end
