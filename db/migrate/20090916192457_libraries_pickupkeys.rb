class LibrariesPickupkeys < ActiveRecord::Migration
  def self.up
  
    create_table :libraries_pickupkeys, :id => false do |t|
       t.integer :library_id, :null => false
       t.integer :pickupkey_id, :null => false
      
       t.timestamps
     end
  end

  def self.down
    drop_table :libraries_pickupkeys
  end
end
