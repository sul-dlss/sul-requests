class AddColForms < ActiveRecord::Migration
  def self.up
    add_column "forms", "mod_by", :string
  end

  def self.down
  end
end
