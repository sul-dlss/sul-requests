class CreateRequests < ActiveRecord::Migration[4.2]
  def change
    create_table :requests do |t|
      t.string :type
      t.date   :needed_date
      t.string :status

      t.timestamps null: false
    end
  end
end
