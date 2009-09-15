class PickupkeysLibraries < ActiveRecord::Migration
  def self.up
    create_table :pickupkeys_libraries, :id => false do |t|
      t.string :pickupkey, :null => false
      t.string :library, :null => false
      
      t.timestamps
    end

  end

  def self.down
    drop_table :pickupkeys_libraries
  end
end
