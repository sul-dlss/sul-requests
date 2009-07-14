class RequestTypesController < ApplicationController
  def index
end

# Method new. Sets up an input form for creating a new request type
  def new
    @request_type = RequestType.new 
    #@request_type.req_type = (params[:req_type])
    #@request_type.current_loc = (params[:current_loc])
    #@request_type.req_status = (params[:req_status])
    #@request_type.form = (params[:form])
    #@request_type.text = (params[:text])
    #@request_type.enabled = (params[:enabled])
    #@request_type.authenticated = (params[:authenticated])
    #create if request.post?
  end
  
  # Method create. Save request type information in database 
  def create
    @request_type = RequestType.new(params[:request_type])
    # Not sure where to send user after form is saved
    @request_type.save
    if @request_type.save
      redirect_to request_types_path
      #redirect_to :action => "index"
    else
      render action=> 'new'
    end
  end
  
  #Method show. Display a single request type
  def show
      @request_type = RequestType.find(params[:id])
  end

  def edit
    @request_type = RequestType.find(params[:id])
    #if request.post?
     #@request_type.update_attributes(params[:request_type])
     #redirect_to :action=>'edit', :id => @request_type.id and return
    #end
    #render :action=> 'new'
  end
  
  # Method update. Saves changes from edit form in database
  def update
    @request_type = RequestType.find(params[:id])
    if @request_type.update_attributes(params[:request_type])
      redirect_to :action => 'show', :id => @request_type
    else
      render :action => 'edit'
    end
  end
  
  def delete
    @Form.find(params[:id]).destroy
      redirect_to :action => 'index'
  end

  # Method index. Display info for all forms.
  def index
      @request_types = RequestType.find(:all)
  end

end
