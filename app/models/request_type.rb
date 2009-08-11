class RequestType < ActiveRecord::Base
  has_and_belongs_to_many :forms
  validates_presence_of :req_type, :current_loc, :req_status
end

class Request_type < ActiveRecord::Base
  has_and_belongs_to_many :forms
  validates_presence_of :req_type, :current_loc, :req_status
end




