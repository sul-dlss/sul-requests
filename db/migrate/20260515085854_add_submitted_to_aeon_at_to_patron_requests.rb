class AddSubmittedToAeonAtToPatronRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :patron_requests, :submitted_to_aeon_at, :datetime
  end
end
