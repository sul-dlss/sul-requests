class AddApprovalStatusColumnToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :approval_status, :integer, default: 0
  end
end
