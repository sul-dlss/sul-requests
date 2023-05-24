class AddMissingUniqueIndexToUser < ActiveRecord::Migration[7.0]
  def change
    add_index :users, :sunetid, unique: true, name: 'unique_users_by_sunetid'

    # Remove old non-unique index
    remove_index :users, column: :sunetid, name: 'index_users_on_sunetid'
  end
end
