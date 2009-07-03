class RequestType < ActiveRecord::Base
  
  validates_presence_of :req_type, :current_loc, :req_status
  
end
