class PickuplibsController < ApplicationController
  def index
  end

  def new
    @pickuplib = Pickuplib.new 
  end
  
  # Method create. Save form information in database 
  def create
    @pickuplib = Pickuplib.new(params[:pickuplib])
    # Not sure where to send user after form is saved
    if @pickuplib.save
      redirect_to pickuplibs_path
    end
  end
  
end
