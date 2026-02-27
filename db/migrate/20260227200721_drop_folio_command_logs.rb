class DropFolioCommandLogs < ActiveRecord::Migration[8.1]
  def change
    drop_table :folio_command_logs
  end
end
