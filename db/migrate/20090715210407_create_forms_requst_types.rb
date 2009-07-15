class CreateFormsRequstTypes < ActiveRecord::Migration
  def self.up     
    create_table :forms_request_types, :id => false do |t|
      t.column :form_id, :integer
      t.column :request_type_id, :integer
    end
  end

  def self.down
    drop_table :forms_request_types
  end
end
