class AddItemInformationToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :origin_location, :string
    add_column :requests, :item_id, :string
  end
end
