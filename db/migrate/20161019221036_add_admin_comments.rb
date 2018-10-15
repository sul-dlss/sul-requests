class AddAdminComments < ActiveRecord::Migration[4.2]
  def change
    create_table :admin_comments do |t|
      t.string :commenter
      t.string :comment
      t.integer :request_id

      t.timestamps null: false
    end
  end
end
