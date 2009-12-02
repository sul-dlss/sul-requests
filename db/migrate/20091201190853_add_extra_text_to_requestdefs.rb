class AddExtraTextToRequestdefs < ActiveRecord::Migration
  def self.up
    add_column :requestdefs, :extra_text, :text
  end

  def self.down
    remove_column :requestdefs, :extra_text
  end
end
