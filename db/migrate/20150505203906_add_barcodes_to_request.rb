class AddBarcodesToRequest < ActiveRecord::Migration
  def change
    add_column :requests, :barcodes, :text
  end
end
