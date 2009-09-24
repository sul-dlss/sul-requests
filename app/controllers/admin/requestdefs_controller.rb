class Admin::RequestdefsController < ApplicationController
  # Method index. Shows all requestdefs
  def index
    @requestdefs = Requestdef.find(:all,  :order => "name")
  end

  # Method show. Display a single requestdef
  def show
  end

  # Method new. Set up and input form for creating a new request def
  def new
    @requestdef = Requestdef.new
    @library_list = [ ['SUL', 'SUL'], ['Hoover', 'HOOVER'],
                    ['Hopkins', 'HOPKINS'], ['Law', 'LAW'], ['SAL 1 & 2', 'SAL'],
                    ['SAL Newark', 'SALNEWARK'], ['SAL 3', 'SAL3']                       
                    ]

  end

  # Method create. Saves data from new input form in database
  def create
    @requestdef = Requestdef.new(params[:requestdef])
    if @requestdef.save
      redirect_to admin_requestdefs_path
    else
      render :action => 'new'
    end
    
  end

  def edit
  end

  # Method update. Saves data from edit form in database
  def update
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

end
