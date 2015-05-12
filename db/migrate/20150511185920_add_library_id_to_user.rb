class AddLibraryIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :library_id, :string
  end
end
