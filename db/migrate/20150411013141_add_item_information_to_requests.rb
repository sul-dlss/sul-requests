class AddItemInformationToRequests < ActiveRecord::Migration[4.2]
  def change
    add_column :requests, :origin_location, :string
    add_column :requests, :item_id, :string
  end
end
