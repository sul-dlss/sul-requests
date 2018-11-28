class AddLocationsToRequests < ActiveRecord::Migration[4.2]
  def change
    add_column :requests, :origin, :string
    add_column :requests, :destination, :string
  end
end
