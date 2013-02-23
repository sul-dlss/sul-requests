    module Requestmod
     
  # Module for both authenticated and unauthenticated requests; also at least 
  # one method used in requests controller

  include Requestutils
  #require 'date'
  
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
        
    # Try checking just for request_def; some SW records don't supply proper
    # current loc to determine request type here 
    if @request.request_def == 'UNDEFINED'  
            
      ExceptionMailer.deliver_problem_report(@request.params, 
                                   "request_def undefined or req_type missing.\n" +
                                    "        Request def is: " + @request.request_def.to_s + "\n" +
                                    "        Request type is: " + @request.req_type.to_s + "\n" )
      flash[:system_problem] = @messages['000']                                  
      
      render :template => 'requests/app_problem' and return false
      
    else    
       
      #===== Check whether we need to redirect to the auth path and redirect if so
       
      if @request.redir_check
        # RubyMine complains that to_query needs an arg but this works as is; may need to revisit at some point
        # cf http://apidock.com/rails/ActiveSupport/CoreExtensions/Hash/to_query for 3 apparently
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
      @sym_info = Syminfo.new( @request.params, @request.home_lib, @request.home_loc, request.env )
      
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
      
      #======= Set request home_loc and home_lib from sym_info if necessary
      
      if @request.home_loc.blank? && ! @sym_info.home_loc.blank?
        @request.home_loc = @sym_info.home_loc
      end    
      
      # Revert for ON-ORDER with no home_lib
      if ( @request.home_lib.blank? || @request.home_lib = 'ON-ORDER' ) && ! @sym_info.home_lib.blank?
        @request.home_lib = @sym_info.home_lib
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
    
    @request = Request.new(params[:request], request.env, request.referrer)

    @messages = get_msg_hash(Message.find(:all))
   
    flash[:invalid_fields] = ''
    error_msgs = check_fields( params['request'], @request.max_checked)

    if ! error_msgs.empty? # Go back to form and display errors; used flash.now so errors don't persist
      
      flash.now[:invalid_fields] = error_msgs
      
      # ---- Reset instance vars needed to re-display form
      @requestdef_info = Requestdef.find_by_name( @request.request_def )
      #@requestdef = @request.request_def
      @request.pickupkey = get_pickup_key( @request.home_lib, @request.home_loc, @request.current_loc, @request.req_type )       
      @pickup_libs_hash = get_pickup_libs( @request.pickupkey)
      
      #====== Get symphony info needed to return to request screen
      @sym_info = Syminfo.new( @request.params, @request.home_lib, @request.home_loc, request.env )
      
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
      @library_names = get_library_names
      
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
  
  # Make a hash of library codes and library descriptions so we can show
  # the description (display name) on the confirmation page that corresponds to the code
  def get_library_names
  
    libraries = Library.find(:all, :select => 'libraries.lib_code, libraries.lib_descrip' )
  
    libraries_hash = Hash.new
    
    for library in libraries
      libraries_hash.merge!(library.lib_code => library.lib_descrip)
    end
  
    return libraries_hash
  
  end # get_library_names
  
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
  
  # Check whether a date string in the form "mm/dd/yyy" is
  # in a range starting from x days before today and
  # ending x days after today. Return true or false
  def check_valid_date?( date_str, days_before, days_after )

    date_to_check = Date.strptime(date_str, "%m/%d/%Y")

    if date_to_check >= Date.today + days_before && date_to_check <= Date.today + days_after
      return true
    else
     return false
    end

end

  # Take items checked strings and return an array of all current locations they contain
  def get_items_cur_locs_checked(items_checked)
    
    # 36105005424713|GREEN|PR6003 .E282 1969 V.16|STACKS|CHECKEDOUT|REQ-HOLD|6/30/2011,23:59
    
    locs_array = []
    
    items_checked.each do |item|
      item_strings = item.split('|')
      locs_array.push( item_strings[4] )
    end
    
    # print "=========== locs array is: " + locs_array.inspect
    
    return locs_array
    
  end

  # Check whether we need to require an ID for this request. Return true or false. 
  # Result will depend on various combinations of home_lib, current_loc and presence
  # of certain current loc strings in items_checked array
  def is_id_needed?(home_lib, current_loc, items_checked)
    
    # puts "============== items checked in is_id_needed is: " + items_checked.inspect
    
    id_decision = true # Make this the default
    
    cur_locs_checked = get_items_cur_locs_checked(items_checked)
    
    # First check that cur_locs don't include checked out locs or on-order, which always
    # require and ID. Do we need to add other sets of locations from Constants?
    if ( CHECKED_OUT_LOCS & cur_locs_checked ).any? ||
      ( MISSING_LOCS & cur_locs_checked ).any? ||
      ( ['ON-ORDER', 'NEWBOOKS'] & cur_locs_checked).any?
      
      id_decision = true
    
    # Now we check for other conditions that remove the requirement for an ID  
    else  
      
      # Cur locs include inprocess
      if (['INPROCESS', 'INTRANSIT'] & cur_locs_checked).any?
        
        id_decision = false
    
      # Then any SAL items that didn't have the above locations 
      elsif ['SAL', 'SAL-NEWARK', 'SAL3'].include?(home_lib) 
     
        id_decision = false 
   
      # Then any SPEC-COLL, Hoover, Hoover Archives items with -30 current loc     
      elsif ['SPEC-COLL', 'HOOVER', 'HV-ARCHIVE'].include?(home_lib)  &&
      current_loc =~ /.*?-30$/
     
        id_decision = false

      end # SAL etc. check

    end # checked out + on-order check
       
    return id_decision
    
  end

  
  # Method check_fields. Test validity of each required field and add to error_msgs
  # if there's a problem
  def check_fields(params, max_checked)
    
    error_msgs = []
    
    # ---- Your name
    
    if ! params['patron_name'].nil?
      
      if params['patron_name'] == ''
        error_msgs.push('Name field cannot be blank.')
      end
      
    end  
    
    # If we have checked items, find out whether ID is needed

    if ! params[:items_checked].nil?
      is_id_needed = is_id_needed?(params[:home_lib], params[:current_loc], params[:items_checked])
    end
    
    
    # puts " ================== Current loc parameter is: " + params[:current_loc]
    
    #------ Library_id or univ_id; only needed if is_id_needed = true
   
    # puts "============= items checked before is_id_needed? is: " + params[:items_checked].inspect
    
    if ! params[:items_checked].nil? &&  is_id_needed 
    
      if ! params['univ_id'].nil?
        
        if params['univ_id'] == ''
          error_msgs.push('University ID cannot be blank.')
        end
        
      end    
      
      if ! params['library_id'].nil?
        
        if params['library_id'] == ''
          error_msgs.push('Library ID cannot be blank.')
        end
        
      end
    
    end # if ID is needed 
    
    # ------- Require something in e-mail if we don't have univ_id or library_id

    if ( ! params[:items_checked].nil? &&  ! is_id_needed  ) &&     
      params['univ_id'].blank? && 
      params['library_id'].blank? &&
      params['patron_email'].blank?
      
      error_msgs.push('Please either fill in your Library ID or enter your e-mail address or phone number in the E-mail field.')
    end
    
    # ------- Not Needed After or planned use
    
    if ! params['not_needed_after'].nil?
      
      begin
          
        if params['not_needed_after'] !~  /^[01][0-9]\/[0-9]{2}\/[0-9]{4}$/ ||
          ! check_valid_date?( params['not_needed_after'], NOT_NEEDED_AFTER_START, 
            NOT_NEEDED_AFTER_END)
          start_date = Date.today + NOT_NEEDED_AFTER_START
          end_date = Date.today + NOT_NEEDED_AFTER_END
          error_msgs.push('Not needed after field must contain a date between ' +
          start_date.strftime("%m/%d/%Y") + ' and ' + end_date.strftime("%m/%d/%Y") +
          ' in the form MM/DD/YYYY.')
        end
        
      rescue ArgumentError # this is invalid_date?
        
        error_msgs.push('You entered an invalid date. Please enter the month followed by the day followed by the year: (MM/DD/YYYY)')
        
      end # rescue structure
      
    end  
    
    if ! params['planned_use'].nil?
      
      begin
           
        if params['planned_use'] !~  /^[01][0-9]\/[0-9]{2}\/[0-9]{4}$/ ||
          ! check_valid_date?( params['planned_use'], PLANNED_USE_START, 
            PLANNED_USE_END )
          start_date = Date.today + PLANNED_USE_START
          end_date = Date.today + PLANNED_USE_END 
          error_msgs.push('Planned use field must contain a date between ' +
          start_date.strftime("%m/%d/%Y") + ' and ' + end_date.strftime("%m/%d/%Y") +
          ' in the form MM/DD/YYYY.')      
        end
      
      rescue ArgumentError # this is invalid_date?
        
        error_msgs.push('You entered an invalid date. Please enter the month followed by the day followed by the year: (MM/DD/YYYY)')
         
      end
      
    end  
    
    # -------- Items: should always have an items field so it should never be nil
    
    if params['items_checked'].nil? || params['items_checked'].empty?
        error_msgs.push('Please select at least one item.')    
    end
    
    if ! params['items_checked'].nil? && params['items_checked'].size > max_checked
      error_msgs.push('Please select no more than ' + max_checked.to_s + ' items.')      
    end
    
    # -------- Pickup library should not be NONE 
    
    if params['pickup_lib'].eql?('NONE')
      error_msgs.push( 'Please select a pickup library.' )
    end
    
    # ------- Check that the lenght of comments is 2000 or less
    
    if ! params['comments'].nil? && params['comments'].length > 2000
      error_msgs.push( 'Please include no more than 2000 characters in the comments field. It currently includes ' + params['comments'].length.to_s + ' characters.')
    end

    return error_msgs
      
  end # check_fields

  
end