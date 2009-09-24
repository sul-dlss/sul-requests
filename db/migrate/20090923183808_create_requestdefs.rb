class CreateRequestdefs < ActiveRecord::Migration
  def self.up
    create_table :requestdefs do |t|
      t.string :name
      t.string :library
      t.string :current_loc
      t.string :req_status
      t.string :req_type
      t.boolean :enabled
      t.boolean :authenticated
      t.boolean :unauthenticated
      t.string :title
      t.text :initial_text
      t.text :final_text

      t.timestamps
    end
  end

  def self.down
    drop_table :requestdefs
  end
end
