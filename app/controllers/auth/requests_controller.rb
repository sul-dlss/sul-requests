class Auth::RequestsController < ::RequestsController
  
  before_filter :is_authenticated?
  
  include Requestmod
     
end
