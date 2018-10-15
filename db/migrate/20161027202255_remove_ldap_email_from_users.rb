class RemoveLdapEmailFromUsers < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :ldap_email, :string
  end
end
