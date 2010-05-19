module Requestmod
     
  # Module for both authenticated and unauthenticated requests; also at least 
  # one method used in requests controller

  include Requestutils
  
  # Method new. Display a request form, including data retrieved from an XML lookup and user data from 
  # the authentication, if available. The user fills in this from to create a request. Note that this
  # method could be called from create method if validation fails, so we need to check whether we 
  # already have various pieces of information before we generate it by calling other methods. This 
  # includes req_type, bib_info, and others. 
  def new
        
    #===== Instantiate request from params passed in + request.env   
    @request = Request.new(params, request.env, request.referrer)
    
    # puts "========== request.referrer in requestmod is: " + request.referrer.inspect
    
    # puts '================ @request.params in Request.new is: ' + @request.params.inspect
    
    #===== Get the params back from the object, since they may have changed
    @params = @request.params
    
    #====== Add msgs because we need some for various screens
    @messages = get_msg_hash(Message.find(:all))    
        
    #===== Check whether we have req_def and req_type & redirect if we do not 
        
    if @request.request_def == 'UNDEFINED' || @request.req_type == 'UNDEFINED'
            
      ExceptionMailer.deliver_problem_report(@request.params, 
                                   "request_def undefined or req_type missing.\n" +
                                    "        Request def is: " + @request.request_def.to_s + "\n" +
                                    "        Request type is: " + @request.req_type.to_s + "\n" )
      flash[:system_problem] = @messages['000']                                  
      
      render :template => 'requests/app_problem' and return false
      
    else    
       
      #===== Check whether we need to redirect to the auth path and redirect if so
       
      if @request.redir_check        
        redirect_to "/auth/requests/new?" + 
        @request.params.to_query + "&redir_done=y" and return false
      end
      
      #====== Clean out any unnecessary params at this point

      if params.has_key?(:p_auth)
        params.delete(:p_auth)
      end
      
      if params.has_key?(:redir_done)
        params.delete(:redir_done)
      end

      #======= Get Symphony bib, item, and cur locs info, and make sure home_loc is set
      @sym_info = Syminfo.new( @request.params, @request.home_lib, @request.home_loc )
      
      #====== Check that we have either a request or sym_info home loc or inclusion test in sym_info will fail
  
      if @request.home_loc.nil? && ( @sym_info.home_loc.nil? || @sym_info.home_loc == 'UNDEFINED' ) 
      
        ExceptionMailer.deliver_problem_report(params, 
                                   "home_loc or home_lib is missing.\n" +
                                    "        Request home_loc is: " + @request.home_loc.to_s + "\n" +
                                    "        Request home_lib is: " + @request.home_lib.to_s + "\n" + 
                                    "        Sym_info home_loc is: " + @sym_info.home_loc.to_s + "\n"
                                    )
        flash[:system_problem] = @messages['000']
 
        render :template => 'requests/app_problem' and return false
      
      end      
      
      # puts "============== request.home_loc: " + @request.home_loc.inspect 
      
      if @request.home_loc.blank? && ! @sym_info.home_loc.blank?
        @request.home_loc = @sym_info.home_loc
      end    
     
      #====== Get info for request def -- form text, etc.
      @requestdef_info = Requestdef.find_by_name( @request.request_def )
        
      #===== Get pickup_libs list    
      @request.pickupkey = get_pickup_key( @request.home_lib, @request.home_loc, @request.current_loc, @request.req_type )   
      @pickup_libs_hash = get_pickup_libs( @request.pickupkey)
          
      #===== Get message keys to display on request screen and list of fields to display           
      @msg_keys = get_msg_keys(@request.home_lib, @sym_info.cur_locs)  
      @fields = get_fields_for_requestdef( @requestdef_info, @sym_info.items )
      
    end # test for requestdef
         
  end # new method
  

  # Method create. Send user input to Oracle stored procedure that creates
  # a request and sends back either a confirmation or error message
  def create
    
    # puts "===================== params requests at start of create: " + params[:request].inspect + "\n"
    
    @request = Request.new(params[:request], request.env)

    @messages = get_msg_hash(Message.find(:all))
   
    flash[:invalid_fields] = ''
    error_msgs = check_fields( params['request'])

    if ! error_msgs.empty? # Go back to form and display errors
      
      flash[:invalid_fields] = error_msgs
      
      # ---- Reset instance vars needed to re-display form
      @requestdef_info = Requestdef.find_by_name( @request.request_def )
      #@requestdef = @request.request_def
      @request.pickupkey = get_pickup_key( @request.home_lib, @request.home_loc, @request.current_loc, @request.req_type )       
      @pickup_libs_hash = get_pickup_libs( @request.pickupkey)
      
      #====== Get symphony info needed to return to request screen
      @sym_info = Syminfo.new( @request.params, @request.home_lib, @request.home_loc )
      
      if @request.home_loc.blank? && ! @sym_info.home_loc.blank?
        @request.home_loc = @sym_info.home_loc
      end
      
      #====== Get msg keys and fields
      @msg_keys = get_msg_keys(@request.home_lib, @sym_info.cur_locs)  
      @fields = get_fields_for_requestdef( @requestdef_info, @sym_info.items )
      
      #====== Return to request screen
      render :action => 'new'
      
    else # Send info to Symphony and display returned message
  
      @symresult = Symresult.new(params, @messages)
              
      # Following is just temporary for debugging
         
      flash[:debug] = "Result is: " + @symresult.result +
         " <P>Param string is: " + @symresult.parm_list
           
      # Add other info for confirmation page

      @requestdef = Requestdef.find_by_name( @request.request_def )
      
      # Get all fields here so we can use labels on confirm page
      @field_labels = get_field_labels
      
      @return_url = @request.return_url
      
      # Render auth or unauth confirm page
      if @is_authenticated
        render :template => "auth/requests/confirm"
      else 
        render :template => "requests/confirm"
      end

    end
  end
   
  # Method not_authenticated. Just show not_authenticated page
  def not_authenticated
    render :template => "requests/not_authenticated"
  end

  
  # Method get_pickup_libs. Take a pickupkey and return an hash of one
  # or more pickuplibs. Should have both lib code and label
  def get_pickup_libs( pickupkey)
       
    # See http://apidock.com/rails/ActiveRecord/Base/find/class
    # Example find by associated table
    
    pickup_libs = Library.find(:all,
      :select => 'libraries.lib_code, libraries.lib_descrip',
      :conditions => ['pickupkeys.pickup_key = ?', pickupkey],
      :joins => [:pickupkeys],
      :order => 'libraries.lib_code'   
      )
      
    # Now we put into a hash and return it sorted. Seems like there should
    # be an easier way of getting the list of libraries!! 
      
    pickup_libs_hash = Hash.new
    
    for pickuplib in pickup_libs
      pickup_libs_hash.merge!({pickuplib.lib_descrip => pickuplib.lib_code})  
    end  
    
    # Add "[Select One From List Below]", "NONE" to the hash if we have more than one item
    
    if pickup_libs_hash.length > 1
      pickup_libs_hash.merge!({' (Select a library) ' => 'NONE'})
    end

    return pickup_libs_hash.sort
    
  end # get_pickup_libs
  
  # Method get field labels. Make a hash of fields names and labels from 
  # data stored in fields table
  def get_field_labels
    
    fields = Field.find(:all,
    :select => 'fields.field_name, fields.field_label'
    )
    
    fields_hash = Hash.new
    
    for field in fields
      fields_hash.merge!({field.field_name => field.field_label} )
    end
    
    return fields_hash
    
  end # get_field_lables
  
  # Method get_fields_for_requestdef. Take a requestdef name and return a hash
  # of fields for that requestdef. Again this seems rather complicated but 
  # couldn't see anyway to get fields when we get @requestdef
  def get_fields_for_requestdef( request_def, items )
    
    # puts "========== request def fields starting get_fields_for_requestdef: " + request_def.fields.inspect
    
    fields_hash = {}
    
    request_def.fields.each do |f|
      fields_hash.merge!({f.field_name => f.field_label})
    end    
    
    # Add req/hold field if necessary (need to add more strings to test here)
    
    if ! items.nil?
    
      if items.to_s.include?('^CHECKEDOUT') || items.to_s.include?('^INPROCESS') || 
          items.to_s.include?('^ON-ORDER') 
        fields_hash.merge!({'hold_recall' => 'Unavailable Items'})
      end    
    
    end
  
    # Always in include both univ ID and library ID. We display these depending on authentication
    # status not on presence in the hash and we need labels for both. Note that we have to hard-code
    # labels here because we don't want to do db lookups for them.
    
    if ! fields_hash.has_key?('univ_id')
      fields_hash.merge!({'univ_id' => 'University ID'})
    end
  
    if ! fields_hash.has_key?('library_id')
      fields_hash.merge!({'library_id' => 'Library ID'})
    end  
    
    return fields_hash
    
  end # get_fields

  # Method get_msg_keys. Take an array of current locations, test to see whether
  # they should cause the display of optional messages on the request form, and return
  # an array of keys for any that should be displayed 
  def get_msg_keys( home_lib, cur_locs )
    
    # puts "========= cur_locs in get_msg_keys: " + cur_locs.inspect + "\n"
    
    msg_keys = []   
    da = 'DELAYED'
       
    if ( cur_locs & NON_PAGE_LOCS ).any?
      msg_keys.push(da)
    end 
       
    if (cur_locs.to_s =~ /-LOAN/)
      msg_keys.push(da) unless msg_keys.include?(da)
    end
  
    return msg_keys
    
  end # get_msg_keys
  
  # Method get_msg_hash. Take the messages retrieved from the DB
  # and put them into a hash with the msg_number as key
  def get_msg_hash(msgs)
    
    msg_hash = {}
    msgs.each do |msg|
      msg_hash[msg.msg_number] = msg.msg_text
    end
    
    return msg_hash
    
  end # get_msg_hash
  
  # Method check_fields. Test validity of each required field and add to error_msgs
  # if there's a problem
  def check_fields(params)
    
    error_msgs = []
    
    # ---- Your name
    
    if ! params['patron_name'].nil?
      
      if params['patron_name'] == ''
        error_msgs.push('Name field cannot be blank')
      end
      
    end  
    
    #------ Library_id or univ_id; only needed if lib not SAL, SAL-NEWARK, or SAL3
    
    if ! ['SAL', 'SAL-NEWARK', 'SAL3'].include?(params[:home_lib])
    
      if ! params['univ_id'].nil?
        
        if params['univ_id'] == ''
          error_msgs.push('University ID cannot be blank')
        end
        
      end    
      
      if ! params['library_id'].nil?
        
        if params['library_id'] == ''
          error_msgs.push('Library ID cannot be blank')
        end
        
      end
    
    end # check for SAL* home_lib
    
    # ------- Not Needed After
    
    if ! params['not_needed_after'].nil?
      
      if params['not_needed_after'] !~  /^[01][0-9]\/[0-9]{2}\/[0-9]{4}$/ 
        error_msgs.push('Not Needed After field must contain a date in the form MM/DD/YYYY')
      end
      
    end  
    
    # -------- Items: should always have an items field so it should never be nil
    
    if params['items_checked'].nil? || params['items_checked'].empty?
        error_msgs.push('Please select at least one item.')    
    end
    
    # -------- Pickup library should not be NONE 
    
    if params['pickup_lib'].eql?('NONE')
      error_msgs.push( 'Please select a pickup library.' )
    end

    return error_msgs
      
  end # check_fields

  
end