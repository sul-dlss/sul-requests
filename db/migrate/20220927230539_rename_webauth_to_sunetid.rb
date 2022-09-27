class RenameWebauthToSunetid < ActiveRecord::Migration[6.1]
  def up
    rename_column :users, :webauth, :sunetid
    rename_index :users, 'index_users_on_webauth', 'index_users_on_sunetid'
  end

  def down
    rename_column :users, :sunetid, :webauth
    rename_index :users, 'index_users_on_sunetid', 'index_users_on_webauth'
  end
end
