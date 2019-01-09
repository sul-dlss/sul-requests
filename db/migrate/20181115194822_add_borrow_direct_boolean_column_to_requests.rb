class AddBorrowDirectBooleanColumnToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :via_borrow_direct, :boolean, default: false
  end
end
