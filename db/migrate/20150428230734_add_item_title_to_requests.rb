class AddItemTitleToRequests < ActiveRecord::Migration[4.2]
  def change
    add_column :requests, :item_title, :string
  end
end
