class RemoveUnusedPatronRequestFields < ActiveRecord::Migration[8.1]
  def change
    remove_column :patron_requests, :folio_request_id, :string
    remove_column :patron_requests, :mediation_status, :string
    remove_column :patron_requests, :status, :string
  end
end
