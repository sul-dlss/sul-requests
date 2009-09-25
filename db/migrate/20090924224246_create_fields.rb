class CreateFields < ActiveRecord::Migration

  def self.up
    create_table :fields do |t|
      t.string :field_name
      t.string :field_label
      t.integer :field_order

      t.timestamps
    end
  end  

  def self.down
  end
end
