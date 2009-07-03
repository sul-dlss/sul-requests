class ChangeTypeColRequestTypes < ActiveRecord::Migration
  def self.up
    rename_column "request_types", "type", "req_type"
  end

  def self.down
  end
end
