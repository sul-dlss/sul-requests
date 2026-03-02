class AddUserToPatronRequests < ActiveRecord::Migration[8.1]
  def change
    add_reference :patron_requests, :user, type: :bigint, null: true, foreign_key: true
  end
end
