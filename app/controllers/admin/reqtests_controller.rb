class Admin::ReqtestsController < ApplicationController
  
  before_filter :is_authenticated?
  
  include Requestutils
  helper_method :get_req_def, :parse_soc_url
    
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
    soc_link_params = parse_soc_url(params[:reqtest][:socrates_link])
    req_type = get_request_type(soc_link_params)
    req_def = get_req_def( soc_link_params[:home_lib], soc_link_params[:current_loc] )
    @reqtest.req_def = req_def
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
  
  #========== Protected methods ===========================
  protected
  
  # Method get_coverage. See how many types defined in requestdefs table 
  # are present or not present in reqtest table
  def get_coverage
    
    # Find all names in requestdefs table
    request_defs = Requestdef.find(:all, :select => 'name', :order => 'name').map(&:name)
    # puts "========== requestdefs is: " + request_defs.inspect
    # Find all distinct req_defs in reqtests table
    req_test_defs = Reqtest.find( :all, :select => 'DISTINCT req_def').map(&:req_def)
    # puts "========== req_tests is: " + request_defs.inspect
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
