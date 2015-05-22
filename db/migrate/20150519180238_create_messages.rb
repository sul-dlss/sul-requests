class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.text :text
      t.datetime :start_at
      t.datetime :end_at
      t.string :library
      t.string :request_type

      t.timestamps null: false
    end
  end
end
