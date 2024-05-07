class AddMediationStatusToPatronRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :patron_requests, :mediation_status, :string

    add_index :patron_requests, :needed_date
    add_index :patron_requests, :mediation_status
  end
end
