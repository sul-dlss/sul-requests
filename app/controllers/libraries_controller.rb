class LibrariesController < ApplicationController
  
  def index
    @libraries = Library.find(:all)
  end

 # Method create. Save library information in database 
  def create
    @library = Library.new(params[:library])
    # Not sure where to send user after form is saved
    if @library.save
      redirect_to libraries_path
    end
  end
  
end
