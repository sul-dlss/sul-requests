class AddLocationToRequests < ActiveRecord::Migration[7.0]
  def change
    add_column :requests, :location, :string
  end
end
