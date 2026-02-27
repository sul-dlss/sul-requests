class DropRequests < ActiveRecord::Migration[8.1]
  def change
    drop_table :requests
  end
end
