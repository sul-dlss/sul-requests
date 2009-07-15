class RequestTypesController < ApplicationController
  def index
end

# Method new. Sets up an input form for creating a new request type
  def new
    @request_type = RequestType.new 
    @forms = Form.find(:all)
  end
  
  # Method create. Save request type information in database 
  def create
    @request_type = RequestType.new(params[:request_type])
    # Is following line needed?? I seem to see some examples with 
    # and some without, but nothing seems to be saved if its missing
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
  
  # Method edit. Same as new method but couldn't get this to 
  # work with new .erb file
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
