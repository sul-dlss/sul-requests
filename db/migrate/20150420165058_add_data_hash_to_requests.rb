class AddDataHashToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :data, :text
  end
end
