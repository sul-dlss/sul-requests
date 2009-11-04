class RequestsController < ApplicationController
  
  include Requestmod
  
  def newx
    @requestx = Request.new
    @requestx.ckey = (params[:ckey])
    
  end
     
end
