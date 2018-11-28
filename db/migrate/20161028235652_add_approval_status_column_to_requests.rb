class AddApprovalStatusColumnToRequests < ActiveRecord::Migration[4.2]
  def change
    add_column :requests, :approval_status, :integer, default: 0
  end
end
