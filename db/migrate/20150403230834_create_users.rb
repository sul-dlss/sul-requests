class CreateUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :users do |t|
      t.string :webauth
      t.string :name
      t.string :email

      t.timestamps null: false
    end
  end
end
