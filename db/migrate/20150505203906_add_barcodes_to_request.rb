class AddBarcodesToRequest < ActiveRecord::Migration[4.2]
  def change
    add_column :requests, :barcodes, :text
  end
end
