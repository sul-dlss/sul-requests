class AddOtpSecretToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :otp_secret, :string
  end
end
