class AddLdapEmailToUser < ActiveRecord::Migration
  def change
    add_column :users, :ldap_email, :string
  end
end
