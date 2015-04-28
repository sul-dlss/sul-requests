class AddItemTitleToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :item_title, :string
  end
end
