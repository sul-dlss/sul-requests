class Admin::ReqtestsController < ApplicationController
  
  before_filter :is_authenticated?
  
  include Requestmod
  helper_method :get_req_def, :parse_url
    
  def index
    @reqtests = Reqtest.find(:all,  :order => "id")
    @coverage = get_coverage
  end

  # Method show. Display a single reqtest
  def show
  end

  # Method new. Set up an input form for creating a new reqtest
  def new
    @reqtest = Reqtest.new
    #find(:all, :select => "name").map(&:name)
    #@req_defs = Requestdef.find(:all, :select => 'name', :order => 'name').map(&:name).insert(0, "NONE")
    
  end
  
  # Method create. Saves data from new input form in database
  def create
    @reqtest = Reqtest.new(params[:reqtest])
    @req_defs = Requestdef.find(:all, :select => 'name', :order => 'name').map(&:name).insert(0, "NONE")
    if @reqtest.save
      #redirect_to :action => 'edit', :id => @requestdef
      redirect_to admin_reqtests_path
    else
      render :action => 'new'
    end
    
  end  
  
  def edit
     @reqtest = Reqtest.find(params[:id])
     @req_defs = Requestdef.find(:all, :select => 'name', :order => 'name').map(&:name).insert(0, "NONE")
   end

  # Method update. Saves data from edit form in database
  def update
    @reqtest = Reqtest.find(params[:id])
    @req_defs = Requestdef.find(:all, :select => 'name', :order => 'name').map(&:name).insert(0, "NONE")    
    if @reqtest.update_attributes(params[:reqtest])
      redirect_to admin_reqtests_path
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    Reqtest.find(params[:id]).destroy
    redirect_to :action => 'index'
  end
  
  def parse_url( url )

    # Get rid of any '%20') string; may be more trailing crud
    url.gsub!("'%20)'", "")
    url.gsub!("%20')", "")
    url.gsub!("'%20)", "")
    url.gsub!("%20", "") # always last

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

    # Add a ninth element if we have only 8
    if parms.length == 8
      parms.push("")
    end

    # Set up keys and create a hash of keys and parms as values
    keys = [:session_id, :action_string, :ckey, :home_lib, :cur_loc, :call_num, :item_id, :req_type, :date]

    parms_hash = Hash[*keys.zip(parms).flatten]

    return parms_hash

  end
  
  #========== Protected methods ===========================
  protected
  
  # Method get_coverage. See how many types defined in requestdefs table 
  # are present or not present in reqtest table
  def get_coverage
    
    # Find all names in requestdefs table
    request_defs = Requestdef.find(:all, :select => 'name', :order => 'name').map(&:name)
    
    # Find all distinct req_defs in reqtests table
    req_test_defs = Reqtest.find( :all, :select => 'DISTINCT req_def').map(&:req_def)
   
    # Get intersection and difference of the two arrays
    covered = request_defs & req_test_defs
    if covered.length == 0
      covered.push('NONE')
    end
    not_covered = request_defs - req_test_defs
    
    # Return result as space-separated strings
    return covered.join(" "), not_covered.join(" ")
    
  end


end
