class ChangePatronRequestDataToLongtext < ActiveRecord::Migration[7.1]
  def up
    change_column :patron_requests, :data, :text, limit: 4294967295
  end

  def down
    change_column :patron_requests, :data, :text
  end
end
