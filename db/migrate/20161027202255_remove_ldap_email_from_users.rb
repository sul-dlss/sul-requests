class RemoveLdapEmailFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :ldap_email, :string
  end
end
