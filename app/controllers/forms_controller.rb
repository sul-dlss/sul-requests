class FormsController < ApplicationController
  def index
  end

# Method new. Sets up an input form for creating a new request form
  def new
    @form = Form.new 
    @request_type = RequestType.find(:all)
    #@form.form_id = (params[:form_id])
    #@form.title = (params[:title])
    #@form.heading = (params[:heading])
    #@form.before_fields = (params[:before_fields])
    #@form.after_fields = (params[:after_fields])
  end
  
 # Method create. Save form information in database 
  def create
    @form = Form.new(params[:form])
    # Not sure where to send user after form is saved
    if @form.save
      redirect_to forms_path
    end
  end
  
  def edit
    @form = Form.find(params[:id])
    @request_type = Request_type.find(:all)
  end
  
  # Method update. Saves changes from edit form in database
  def update
    @form = Form.find(params[:id])
    if @form.update_attributes(params[:form])
      redirect_to :action => 'show', :id => @form
    else
      render :action => 'edit'
    end
  end  
  
  # Method delete. Delete a record from the database.
   def delete
      Form.find(params[:id]).destroy
      redirect_to :action => 'index'
   end

  
  #Method show. Display a single form
  def show
      @form = Form.find(params[:id])
  end


  # Method index. Display info for all forms.
  def index
      @forms = Form.find(:all)
  end




end
