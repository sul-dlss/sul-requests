class Auth::RequestsController < ApplicationController
  
  before_filter :is_authenticated?
  
  include Requestmod
     
end
