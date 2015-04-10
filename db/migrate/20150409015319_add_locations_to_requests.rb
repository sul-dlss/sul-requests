class AddLocationsToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :origin, :string
    add_column :requests, :destination, :string
  end
end
