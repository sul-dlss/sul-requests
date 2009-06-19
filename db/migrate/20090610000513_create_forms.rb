class CreateForms < ActiveRecord::Migration
  def self.up

    create_table :forms do |t|
      t.string :form_id
      t.string :title
      t.string :heading
      t.string :before_fields
      t.string :after_fields

      t.timestamps
    end
  end

  def self.down
    drop_table :forms
  end
end
