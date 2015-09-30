class AddEstimatedDeliveryToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :estimated_delivery, :string
  end
end
