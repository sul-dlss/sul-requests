class ChangeRequestItemTitleToText < ActiveRecord::Migration
  def up
    change_column :requests, :item_title, :text
  end

  def down
    # Note that this may cause issues if there is
    # data > 255 characters in the item_title column
    change_column :requests, :item_title, :string
  end
end
