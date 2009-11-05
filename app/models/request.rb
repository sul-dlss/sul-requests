class Request < ActiveRecord::Base
  
  has_no_table
  column :ckey, :string
  column :call_num, :string
  column :item, :array
  column :patron_name, :string
  column :patron_email, :string
  column :library_id, :string
  column :univ_id, :string
  column :sunet_id, :string
  column :pickup_lib, :array
  column :home_lib, :string
  column :current_loc, :string
  column :item_id, :string
  column :vol_num, :string
  column :not_needed_after, :string
  column :due_date, :string
  column :req_type, :string
  column :session_id, :string

  validates_presence_of :patron_name, :univ_id, :pickup_lib
  
end
