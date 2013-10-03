class Library < ActiveRecord::Base
  has_and_belongs_to_many :pickupkeys
  
  attr_accessible :lib_code, :lib_descrip
  
end
