class CreateRequestTypes < ActiveRecord::Migration
  def self.up
    create_table :request_types do |t|
      t.string :type
      t.string :current_loc
      t.string :req_status
      t.string :form
      t.string :text
      t.boolean :enabled
      t.boolean :authenticated

      t.timestamps
    end
  end

  def self.down
    drop_table :request_types
  end
end
