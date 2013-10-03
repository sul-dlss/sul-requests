class Reqtest < ActiveRecord::Base
  validates_presence_of :socrates_link
  
  attr_accessible :socrates_link, :form_status, :request_status, :comments
end
