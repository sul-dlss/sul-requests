class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.string :msg_number
      t.string :msg_text
      t.text :comments

      t.timestamps
    end
  end

  def self.down
    drop_table :messages
  end
end
