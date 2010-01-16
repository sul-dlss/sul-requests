class Admin::ReqtestsController < ApplicationController
  
  before_filter :is_authenticated?
    
  def index
    @reqtests = Reqtest.find(:all,  :order => "req_def")
  end

  # Method show. Display a single reqtest
  def show
  end

  # Method new. Set up an input form for creating a new reqtest
  def new
    @reqtest = Reqtest.new
    #find(:all, :select => "name").map(&:name)
    @req_defs = Requestdef.find(:all, :select => 'name', :order => 'name').map(&:name).insert(0, "NONE")
    
  end
  
  # Method create. Saves data from new input form in database
  def create
    @reqtest = Reqtest.new(params[:reqtest])
    if @reqtest.save!
      #redirect_to :action => 'edit', :id => @requestdef
      redirect_to admin_reqtests_path
    else
      render :action => 'new'
    end
    
  end  
  
  #========== Protected methods ===========================
  protected

  # Method parse_url. Take a Socrates request URL and pull out the pieces we want to use
  # in constructing URLs to Rails forms. Return an array of data in this order
  #   1. Session number of some sort??
  #   2. Webcat "ACTION" string used to send form to Webcat server
  #   3. catalog key, which will be used to get citation data
  #   4. library
  #   5. location
  #   6. call number
  #   7. item ID
  #   8. request type
  #   9. current return date
  def parse_url( url)

    # Get rid of any %20 strings
    url['%20'] = ''

    # Get rid of trailing "')"
    if ( url =~ /^(.*?)'\)$/ )
      url = $1
    end
    
    # Pull out string after p_data=

    if ( url =~ /.*?p_data=(.*)/ )
      url = $1
    end

    # Get rid of leading "|" if any

    if ( url =~ /^\|(.*$)/ )
      url = $1
    end

    # Split into array on |
    parms = Array.new()

    parms = url.split(/\|/)

    return parms

  end

end
