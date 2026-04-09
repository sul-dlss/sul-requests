class UpdateItemId < ActiveRecord::Migration[8.1]
  def change
    change_column :api_responses, :item_id, :text
    change_column :api_responses, :patron_request_id, :bigint, null: false
  end
end
