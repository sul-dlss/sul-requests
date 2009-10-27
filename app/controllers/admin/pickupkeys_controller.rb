class Admin::PickupkeysController < ApplicationController
  def index

    @pickupkeys = Pickupkey.find(:all,  :order => 'pickup_key', 
           :include => :libraries )           
  end
  
  # Method create. Save pickup key information in database 
  def create
    @pickupkey = Pickupkey.new(params[:pickupkey])
    # Not sure where to send user after form is saved
    if @pickupkey.save
      redirect_to admin_pickupkeys_path
    end
  end
  
  # Method edit. Provide the pickupkey identified by the ID passed in 
  # and all libraries. Selected libraries are handled by the view
  def edit
    @pickupkey = Pickupkey.find(params[:id])
    @libraries = Library.find(:all, :order => 'lib_code')
  end
  
  # Method update. Saves changes from edit form in database. The second line
  # takes care of updating the linking table for any select libraries
  def update
    @pickupkey = Pickupkey.find(params[:id])
    @pickupkey.libraries = Library.find(params[:library_ids]) if params[:library_ids]
    if @pickupkey.update_attributes(params[:pickupkey])
      # redirect_to :action => 'show', :id => @pickupkey
      redirect_to admin_pickupkeys_path
    else
      render :action => 'edit'
    end
  end   
  
  #Method show. Display a single pickupkey record
  def show
      @pickupkey = Pickupkey.find(params[:id])
  end  
  
  #Method show. Display a single pickupkey record with its libraries
  def show_libraries
      @pickupkey = Pickupkey.find(params[:id])
  end    
 
  # Method save. Saves libraries info for a pickupkey using AJAX call  
  def save
    @pickupkey = Pickupkey.find(params[:id])
    @library = Library.find(params[:library])
    if params[:show] == "true"
      @pickupkey.libraries << @library
    else
      @pickupkey.libraries.delete(@library)
    end
    @pickupkey.save!
    render :nothing => true
  end
  
  def destroy
    @pickupkey = Pickupkey.find(params[:id])
    @pickupkey.destroy
    redirect_to(admin_pickupkeys_url)
  end

end
