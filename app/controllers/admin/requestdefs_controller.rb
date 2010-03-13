class Admin::RequestdefsController < ApplicationController
  
  before_filter :is_authenticated?
  before_filter :get_lib_list, :only => [:new, :edit, :create ]
  
   # Class instance variable used for new and edit below

  
  # Method index. Shows all requestdefs
  def index
    @requestdefs = Requestdef.find(:all,  :order => "name")
  end

  # Method show. Display a single requestdef
  def show
  end

  # Method new. Set up an input form for creating a new request def
  def new
    @requestdef = Requestdef.new
    @fields = Field.find(:all, :order => 'field_order')    
  end

  # Method create. Saves data from new input form in database
  # Note that we need to go immediately to edit screen after saving new record,
  # since we need a record ID to allow AJAX selection of fields.
  def create
    @requestdef = Requestdef.new(params[:requestdef])
    @fields = Field.find(:all, :order => 'field_order')
    @requestdef.fields = Field.find(params[:field_ids]) if params[:field_ids]
    if @requestdef.save
      #redirect_to :action => 'edit', :id => @requestdef
      redirect_to admin_requestdefs_path
    else
      render :action => 'new'
    end
    
  end

  def edit
     @requestdef = Requestdef.find(params[:id])
     @fields = Field.find(:all, :order => 'field_order')
   end

  # Method update. Saves data from edit form in database
  def update
    @requestdef = Requestdef.find(params[:id])
    @requestdef.fields = Field.find(params[:field_ids]) if params[:field_ids]
    if @requestdef.update_attributes(params[:requestdef])
      # redirect_to :action => 'show', :id => @pickupkey
      redirect_to admin_requestdefs_path
    else
      render :action => 'edit'
    end
  end

  def destroy
    Requestdef.find(params[:id]).destroy
    redirect_to :action => 'index'
  end
  
  # Method save. Saves fields info for a requestdef using AJAX call  
  def save
    @requestdef = Requestdef.find(params[:id])
    @field = Field.find(params[:field])
    if params[:show] == "true"
      @requestdef.fields << @field
    else
      @requestdef.fields.delete(@field)
    end
    @requestdef.save!
    render :nothing => true
  end  
  
  #Method show. Shows single requestdef
  def show
    @requestdef = Requestdef.find(params[:id])
  end
  
  # Method show_fields. Display fields associated with a requestdef
  def show_fields
      @requestdef = Requestdef.find(params[:id])
  end  
  
  protected
  
  def get_lib_list
     @library_list =  [['SUL', 'SUL'], ['Hoover', 'HOOVER'], 
                    ['Hoover Archives', 'HV-ARCHIVE'],
                    ['Hopkins', 'HOPKINS'], ['Law', 'LAW'], ['SAL 1 & 2', 'SAL'],
                    ['SAL Newark', 'SALNEWARK'], ['SAL 3', 'SAL3'], 
                    ['Special Collections', 'SPECCOLL']                       
                    ]
  end

end
