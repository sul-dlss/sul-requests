class CreateLibraries < ActiveRecord::Migration
  def self.up
    create_table :libraries do |t|
      t.string :lib_code
      t.string :lib_descrip

      t.timestamps
    end
  end

  def self.down
    drop_table :libraries
  end
end
