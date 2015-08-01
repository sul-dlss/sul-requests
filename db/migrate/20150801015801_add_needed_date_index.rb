class AddNeededDateIndex < ActiveRecord::Migration
  def change
    add_index :requests, :needed_date
  end
end
