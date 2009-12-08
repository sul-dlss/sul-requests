class ChangeMsgTextOnMessages < ActiveRecord::Migration
  def self.up
    change_column :messages, :msg_text, :text
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration, "Don't want to change type back from text to string"
  end
end
