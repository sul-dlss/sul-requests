class AddLibraryIdToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :library_id, :string
  end
end
