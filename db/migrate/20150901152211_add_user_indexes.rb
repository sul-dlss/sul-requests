class AddUserIndexes < ActiveRecord::Migration
  def change
    add_index :users, :webauth
    add_index :users, :email
    add_index :users, :library_id
  end
end
