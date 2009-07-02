class RequestType < ActiveRecord::Base
  
  validates_presence_of :type, :current_loc, :req_status
  
end
