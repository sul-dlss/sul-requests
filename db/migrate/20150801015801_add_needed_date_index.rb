class AddNeededDateIndex < ActiveRecord::Migration[4.2]
  def change
    add_index :requests, :needed_date
  end
end
