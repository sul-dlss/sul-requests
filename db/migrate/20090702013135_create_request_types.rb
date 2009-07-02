class CreateRequestTypes < ActiveRecord::Migration
  def self.up
    create_table :request_types do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :request_types
  end
end
