class CreatePickupkeys < ActiveRecord::Migration
  def self.up
    create_table :pickupkeys do |t|
      t.string :pickup_key
      t.string :pickup_descrip

      t.timestamps
    end
  end

  def self.down
    drop_table :pickupkeys
  end
end
