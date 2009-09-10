class CreatePickuplibs < ActiveRecord::Migration
  def self.up
    create_table :pickuplibs do |t|
      t.string :lib_key
      t.string :pickup_code
      t.string :pickup_label

      t.timestamps
    end
  end

  def self.down
    drop_table :pickuplibs
  end
end
