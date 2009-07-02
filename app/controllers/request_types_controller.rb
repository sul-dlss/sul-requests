class RequestTypesController < ApplicationController
  def index
end

# Method new. Sets up an input form for creating a new request type
  def new
    @request_type = RequestType.new 
    @request_type.type = (params[:type])
    @request_type.current_loc = (params[:current_loc])
    @request_type.req_status = (params[:req_status])
    @request_type.form = (params[:form])
    @request_type.text = (params[:text])
    @request_type.enabled = (params[:enabled])
    @request_type.authenticated = (params[:authenticated])
  end
  
  # Method create. Save request type information in database 
  def create
    @request_type = RequestType.new(params[:request_type])
    # Not sure where to send user after form is saved
    if @request_type.save
      redirect_to request_types_path
    end
  end
  
  #Method show. Display a single request type
  def show
      @request_type = RequestType.find(params[:id])
  end


  # Method index. Display info for all forms.
  def index
      @request_types = RequestType.find(:all)
  end

end
