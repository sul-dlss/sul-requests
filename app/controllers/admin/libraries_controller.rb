class Admin::LibrariesController < ApplicationController
  
  def index
    #@libraries = Library.find(:all, :order => "lib_code")
    @libraries = Library.order("lib_code").all
  end

 # Method create. Save library information in database 
  def create
    @library = Library.new(params[:library])
    # Not sure where to send user after form is saved
    if @library.save
      redirect_to admin_libraries_path
    end
  end
  
  def edit
    @library = Library.find(params[:id])
  end
  
  # Method update. Saves changes from edit form in database
  def update
    @library = Library.find(params[:id])
    if @library.update_attributes(params[:library])
      redirect_to :action => 'show', :id => @library
    else
      render :action => 'edit'
    end
  end  
  
  #Method show. Display a single library record
  def show
      @library = Library.find(params[:id])
  end
  
  def destroy
    @library = Library.find(params[:id])
    @library.destroy
    redirect_to(admin_libraries_url)
  end
  
end
