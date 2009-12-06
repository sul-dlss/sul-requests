class Request < Tableless
  
  #has_no_table
  column :ckey, :string
  column :call_num, :string
  column :bib_info, :string
  column :items, :array
  column :items_checked, :arrary 
  column :patron_name, :string
  column :patron_email, :string
  column :library_id, :string
  column :univ_id, :string
  column :sunet_id, :string
  column :pickup_lib, :array
  column :home_lib, :string
  column :home_loc, :string
  column :current_loc, :string
  column :item_id, :string
  column :vol_num, :string
  column :not_needed_after, :string
  column :planned_use, :string
  column :due_date, :string
  column :req_type, :string
  column :hold_recall, :string
  column :session_id, :string
  column :comments, :string
  column :request_def, :string
  column :pickupkey, :string

  validates_presence_of :patron_name, :pickup_lib 
  # Following does not work -- nil and blank seem to be the same
  # validates_presence_of :library_id, :allow_blank => :true
  # validates_format_of :not_needed_after, :with => /^[01][0-9]\/[0-9]{2}\/[0-9]{4}$/, :message => 'must be in format "MM/DD/YYY"' 

end
