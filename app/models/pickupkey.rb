class Pickupkey < ActiveRecord::Base
  has_and_belongs_to_many :libraries
  
  def available_libraries
    Library.find(:all, :order => "lib_code ASC")
  end
  
  def chosen?(library)
    libraries.include?(library)
  end
end
