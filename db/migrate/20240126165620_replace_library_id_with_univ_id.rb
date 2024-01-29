class ReplaceLibraryIdWithUnivId < ActiveRecord::Migration[7.0]
  def change
    add_index :users, :univ_id
    remove_index :users, :library_id
    remove_column :users, :library_id
  end
end
