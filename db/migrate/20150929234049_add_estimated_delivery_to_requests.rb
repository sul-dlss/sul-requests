class AddEstimatedDeliveryToRequests < ActiveRecord::Migration[4.2]
  def change
    add_column :requests, :estimated_delivery, :string
  end
end
