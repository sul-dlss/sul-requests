class AddDataHashToRequests < ActiveRecord::Migration[4.2]
  def change
    add_column :requests, :data, :text
  end
end
