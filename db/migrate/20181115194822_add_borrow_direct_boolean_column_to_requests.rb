class AddBorrowDirectBooleanColumnToRequests < ActiveRecord::Migration[4.2]
  def change
    add_column :requests, :via_borrow_direct, :boolean, default: false
  end
end
