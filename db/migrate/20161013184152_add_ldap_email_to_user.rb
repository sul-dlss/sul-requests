class AddLdapEmailToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :ldap_email, :string
  end
end
