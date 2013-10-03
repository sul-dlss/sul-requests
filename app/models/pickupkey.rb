class Pickupkey < ActiveRecord::Base
  has_and_belongs_to_many :libraries
  
  attr_accessible :pickup_key, :pickup_descrip
  
  def available_libraries
    #Library.find(:all, :order => "lib_code ASC")
    Library.order("lib_code ASC").all
  end
  
  def chosen?(library)
    libraries.include?(library)
  end
end
