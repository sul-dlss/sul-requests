class ChangePatronRequestDataToPostgresCompatibleLength < ActiveRecord::Migration[7.1]
  def up
    change_column :patron_requests, :data, :text, limit: 1.gigabyte - 1.byte
  end

  def down
    change_column :patron_requests, :data, :text, limit: 4294967295
  end
end
