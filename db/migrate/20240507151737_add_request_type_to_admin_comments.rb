class AddRequestTypeToAdminComments < ActiveRecord::Migration[7.1]
  def change
    add_column :admin_comments, :request_type, :string, default: 'Request'
    add_index :admin_comments, [:request_type, :request_id]


    reversible do |dir|
      dir.up do
        AdminComment.update_all(request_type: 'Request')
      end
    end
  end
end
