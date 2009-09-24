class CreateFields < ActiveRecord::Migration
  def self.up
    create_table :fields do |t|
      t.string :name
      t.string :label
      t.integer :order

      t.timestamps
    end
  end
  
  # linking table
  
  create_table :fields_requestdefs, :id => false do |t|
       t.integer :field_id, :null => false
       t.integer :requestdef_id, :null => false
      
       t.timestamps
  end

  def self.down
    drop_table :fields_requestdefs
    drop_table :fields
  end
end
