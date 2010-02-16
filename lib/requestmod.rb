module Requestmod
  
  require 'nokogiri'
  require 'open-uri'
  
  # Module for both authenticated and unauthenticated requests; also at least one method used in 
  # requests controller
  
  # Constants for this module - note that -dev and -test both have unpredictable 
  # availability at the moment and this application is unusable if the server 
  # selected here is down.
  Sw_lookup_pre = 'http://searchworks-test.stanford.edu/view/'
  #Sw_lookup_pre = 'http://searchworks-dev.stanford.edu:3000/view/'
  Sw_lookup_suf = '.request'
  
  # Method new. Display a request form, including data retrieved from an XML lookup and user data from 
  # the authentication, if available. The user fills in this from to create a request. Note that this
  # method could be called from create method if validation fails, so we need to check whether we 
  # already have various pieces of information before we generate it by calling other methods. This 
  # includes req_type, bib_info, and others. 
  def new
    
    @request = Request.new
    
    #===== Get params from Socrates URL if necessary and add appropriate source param

    if params.has_key?(:p_data)
      new_params = parse_soc_url('p_data=' + params[:p_data])
      params.delete(:p_data)
      params.merge!(new_params)
      params.merge!(:source => 'SO')
    else
      params.merge!(:source => 'SW')
    end
    
    #===== Get user information
    
    user = get_user
    @request.patron_name = user[:patron_name]
    @request.patron_email = user[:patron_email]
    @request.library_id = user[:library_id]
    
    #===== Get req_type - may not be in parms but need for request_def at the moment
    
    @request.req_type = get_request_type( params )
    
    #===== Get library, which we need to limit items
    
    @request.home_lib = params[:home_lib]
    
    #===== Get the request definition, which is the key to everything else
    
    @request.request_def = get_req_def( params[:home_lib], params[:current_loc], @request.req_type )
        
    if @request.request_def == 'UNDEFINED'
      
      @params = params
      render :template => 'requests/app_problem'
      
    else    
      
      #===== Check whether we need to redirect to the auth path and do the redirect if so
        
      if check_auth_redir( params )
        params.merge!(:redir_done => 'y')
        redirect_to "/auth/requests/new?" +  join_params_hash(params, '=', '&')
      end
      
      #====== Clean out any unnecessary params at this point

      if params.has_key?(:p_auth)
        params.delete(:p_auth)
      end
      
      if params.has_key?(:redir_done)
        params.delete(:redir_done)
      end
      
      #====== Get info for request def -- form text, etc.

      @requestdef = Requestdef.find_by_name( @request.request_def )
        
      #===== Get the pickupkey then the pickup_libs
      
      @request.pickupkey = get_pickup_key( params[:home_lib], params[:current_loc], @request.req_type )       
      @pickup_libs_hash = get_pickup_libs( @request.pickupkey)
          
      #===== Get bib info and item info
      
      multi_info = get_sw_info(params, params[:ckey], params[:home_lib])
      @request.bib_info = multi_info[0].to_s
      @request.items = multi_info[1] # delimited array
      
      puts "================= request items is: " + @request.items.inspect + "\n"
      
      @fields = get_fields_for_requestdef( @requestdef, @request.items )
      
      #===== Get remaining fields from parameters
      
      @request.ckey = (params[:ckey])
      
      # These apply to all items
      @request.pickup_lib = (params[:pickup_lib])
      @request.not_needed_after = (params[:not_needed_after])
      @request.source = (params[:source])
      
      # These are item-specific so apply only at the item level
      @request.due_date = (params[:due_date])
      @request.call_num = (params[:call_num])
      @request.home_lib = (params[:home_lib])
      @request.current_loc = (params[:current_loc])
      @request.item_id = (params[:item_id])
      
    end # test for requestdef
         
  end # new method
  
  # Method check_auth_redir. Take params and return true or false depending 
  # on whether we need to redirect to the auth path. Various conditions for redirecting
  # but note that we've already changed p_data parms into regular parms
  def check_auth_redir(params)
    
    # Redir done so return false
    if params.has_key?(:redir_done)
      return false
    end
    
    # Don't redirect for these libs if coming from SearchWorks
    if params.has_key?(:source) && params[:source] == 'SW' 
      if params.has_key?(:home_lib) && ['SAL', 'SAL3', 'SAL-NEWARK', 'HOPKINS'].include?(params[:home_lib])
        return false 
      end
    end
    
    # Check for current locs, etc. requiring redirect.  
    if params.has_key?(:p_auth)
      return true # Soc auth with auth requirement noted as a param    
    elsif ( params.has_key?(:source) && params[:source] == 'SO' ) && 
          (params.has_key?(:req_type) && ['REQ-RECALL'].include?(params[:req_type]) )
      return true
    elsif params.has_key?(:current_loc) && ['INPROCESS', 'ON-ORDER'].include?(params[:current_loc])
      return true
    end
    
    # If we get this far, just return false
    return false

  end # check auth redir
 
  # Method create. Send user input to Oracle stored procedure that creates
  # a request and sends back either a confirmation or error message
  def create

    @request = Request.new(params[:request])
    
    flash[:invalid_fields] = ''
    error_msgs = check_fields( params['request'])

    if ! error_msgs.empty?
      
      error_msgs.each do |msg|
        if flash[:invalid_fields].blank?
          flash[:invalid_fields] = msg 
        else
          flash[:invalid_fields] = flash[:invalid_fields] + '^' + msg 
        end # if flash blank
      end # do each msg 

      # ---- Put checked items into new items_checked array
      @request.items_checked = @request.items

      # ---- Reset instance vars needed to re-display form
      @requestdef = Requestdef.find_by_name( @request.request_def )
      @pickup_libs_hash = get_pickup_libs( @request.pickupkey)
      
      # Get bib info and item info
      multi_info = get_sw_info(params['request'], @request.ckey, @request.home_lib)
      @request.bib_info = multi_info[0].to_s
      @request.items = multi_info[1] # delimited array
      @fields = get_fields_for_requestdef( @requestdef, @request.items )
      render :action => 'new'
      
    else
  
      # Set up application server and other vars
      symphony_oas = 'http://zaph.stanford.edu:9081'
      path_info = '/pls/sirwebdad/func_request_webservice.make_request?'
      # First we get the items, then the rest of params withouth items
      items = params[:request][:items]
      parm_list = URI.escape( join_params_hash( params[:request], '=', '&' ) )
      parm_list = add_items( parm_list, items)
         
      # Run stored procedure through http (need to check on best way of doing this ).
      # Should we try by running stored proc directly through a db connection defined in .yml file?
      
      url = URI.parse( symphony_oas + path_info + parm_list )
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.get( path_info + parm_list )
      }
         
      # Get results hash from delimited string returned from Symphony
      @results = get_results( res.body ) 
         
      flash[:debug] = "Result is: " + res.body + " <P>Param string is: " + parm_list
      # redirect_to requests_path
      # This needs work. For requests path it's OK. For auth/requests path Rails insists on 
      # going to show.html.erb. Kludge is to create show.html.erb in views/auth/requests but this
      # is idiotic. Logged this in Jira as symreq-3
      #redirect_to :controller => 'requests', :action => 'confirm'
      
      # Need to keep track of items checked to this point in case we return to new form
      @request.items_checked = @request.items
      
      # Add other info for confirmation page
      @messages = get_msg_hash(Message.find(:all))
      @requestdef = Requestdef.find_by_name( @request.request_def )
      
      # Get all fields here so we can use labels on confirm page
      @field_labels = get_field_labels
      
      # puts "field labels in create method is: " + @field_labels.inspect
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
  
  # Make public so we can call it from reqtest controller

  # Method get_req_def. Determine request definition from home_lib, current_loc and req_type
  # Make UNDEFINED the default if nothing else turns up.
  def get_req_def( home_lib, current_loc, req_type )
    
    req_def = 'UNDEFINED'
    
    # First figure out whether we have a generic SUL library or a special library

    if home_lib.upcase != 'HOOVER' && home_lib.upcase != 'LAW' && home_lib.upcase[0..2] != 'SAL'
      home_lib = 'SUL'
    end
    
    # We also need some sets of locations that we need to test for
    
    # Main criterion is current_loc, with everything else depending on that

    # =============== CHECKEDOUT
    
    holdrec_locs = ['CHECKEDOUT', 'CHKD-OUT-D', 'BINDERY',  'NEWBOOKS', 'B&FHOLD', 'ENDPROCESS', 
                   'INTRANSIT', 'MISSING', 'MISS-INPRO', 'REPAIR' ]
  
    if holdrec_locs.include?(current_loc.upcase ) || current_loc.upcase =~ /.*?\-LOAN/
      
      # Req type can be either REQ-HOLD or REQ-REQ-RECALL
      
      # --------------- HOLD
      if req_type.upcase == 'REQ-HOLD' || req_type.upcase == 'REQ-RECALL' 
        
        if home_lib.upcase == 'HOOVER'
          
          req_def = 'HOLDREC-HOV'
          
        elsif home_lib.upcase == 'LAW'
          
          req_def = 'HOLDREC-LAW'
          
        else 
          
          req_def = 'HOLDREC-SUL'
          
        end # home_lib choice
        
        # Note that there's no else here so SAL requests, and maybe others, will fall through.
              
      end 
      
    # ============= INPROCESS 
  
    elsif current_loc.upcase == 'INPROCESS' || current_loc.upcase == 'UNCAT'
    
      if home_lib.upcase == 'HOOVER'
          
          req_def = 'INP-HOV'
          
      elsif home_lib.upcase == 'LAW'
          
          req_def = 'INP-LAW'
          
      else 
          req_def = 'INP-SUL'
          
      end # home_lib choice  
        
    elsif current_loc.upcase == 'ON-ORDER'
      
      if home_lib.upcase == 'HOOVER'
          
          req_def = 'ORD-HOV'
          
      elsif home_lib.upcase == 'LAW'
          
          req_def = 'ORD-LAW'
          
      else 
          req_def = 'ORD-SUL'
          
      end # home_lib choice        

    #=============== STACKS - this is more involved & seems to depend on req_type 
    
    elsif current_loc.upcase == 'STACKS' || current_loc =~ /.*?\-30$/ || current_loc =~ /^PAGE-/ 
    
      if req_type.upcase == 'REQ-HOP' 
        
        req_def = 'REQ-HOPKINS'
        
      elsif req_type.upcase == 'REQ-SAL'
        
        req_def = 'SAL'
        
      elsif req_type.upcase == 'REQ-SAL3'
      
        req_def = 'SAL3'
        
      # Need to look into the following. Probably irrelevant if we have multiple items and fewer forms        
      
      elsif req_type.upcase == 'SAL3-TO-BR'
      
        req_def = 'SAL3-TO-BR'
        
      elsif req_type.upcase == 'SAL3-TO-HA'
        
        req_def = 'SAL3-TO-HA'
 
      elsif req_type.upcase == 'SAL3-TO-HL'
        
        req_def = 'SAL3-TO-HL' 
        
      elsif req_type.upcase == 'SAL3-TO-SP'
        
        req_def = 'SAL3-TO-SP'
        
      end # -- req_type choices
      
    end # -- current_loc choices
    
    return req_def   
    
  end # get_req_def
  
  # Method get_pickup_key. Determine the pickup_key, which indicates the pickup libraries to display
  # from the home_lib, current_loc, and req_type
  def get_pickup_key( home_lib, current_loc, req_type )
    
    pickupkey = ''
    
    # Need to check whether this covers every case
    
    if home_lib.upcase ==  'HOOVER' || home_lib.upcase == 'LAW'
      pickupkey = home_lib
    elsif current_loc[0..4] == 'PAGE-'
      pickupkey = current_loc[5..current_loc.length]
    elsif req_type[0..7] == 'SAL3-TO-'
      pickupkey = req_type[8..req_type.length]      
    end
    
    if pickupkey.blank?
      pickupkey = 'ALL'
    end
    
    return pickupkey
    
  end # get_pickup_key
  
  # Method parse_soc_url. Take a pipe delimited Socrates URL and return a hash of names and values
  # used in a corresponding Rails URL. Note that the input string should start with "p_data="
  def parse_soc_url( url )

    # Get rid of any '%20') string; may be more trailing crud
    url.gsub!("'%20)'", "")
    url.gsub!("%20')", "")
    url.gsub!("'%20)", "")

    # Pull out string after p_data=

    if ( url =~ /.*?p_data=(.*)/ )
      url = $1
    end

    # Get rid of leading "|" if any

    if ( url =~ /^\|(.*$)/ )
      url = $1
    end
    
    # Get rid of any remaining stuff; not sure why we still have anything here!!
    url.gsub!("')", "")
    url.gsub!("%27", "")
    url.gsub!("'", "")
    
    # Split into array on |
    parms = Array.new()

    parms = url.split(/\|/)

    # Add a ninth element if we have only 8
    if parms.length == 8
      parms.push("")
    end

    # Set up keys and create a hash of keys and parms as values
    keys = [:session_id, :action_string, :ckey, :home_lib, :current_loc, :call_num, :item_id, :req_type, :due_date]

    parms_hash = Hash[*keys.zip(parms).flatten]
    
    # Get rid of session_id and action_string, which we don't need
    
    parms_hash.delete(:session_id)
    parms_hash.delete(:action_string)

    return parms_hash

  end # parse_soc_url
  
  
  # ================ Protected methods from here ====================
  protected
  
  # Method get_user. Get user information, normally from the environment and return as a hash
  def get_user 
    
    if request.env['WEBAUTH_USER'].blank?
       user = { :patron_name => '', :univ_id => '', :patron_email => '' }     
       #user = { :patron_name => 'Jonathan Lavigne', :library_id => '2000000603', :patron_email => 'jlavigne@stanford.edu' }     
    else
      user = { :patron_name => request.env['WEBAUTH_LDAP_DISPLAYNAME'], :univ_id => request.env['WEBAUTH_LDAP_SUUNIVID'], :patron_email => request.env['WEBAUTH_LDAP_MAIL'] }
    end
  
    return user
  end

  # Method get_request_type. Return the request type based on other parameters if we don't have
  # one included in the parameters. Logic copied from PL/SQL code for display proc. Not sure whether all of 
  # this is still needed for Socrates but might help with SearchWorks. Note. Need to make some changes from 
  # PL/SQL original. So far added REQ-SAL3 if home_lib is SAL3 and we don't have INPROCESS, CHECKEDOUT,
  # or Hoover or Law stuff. Probably need other SAL3 options for the various special cases of SAL3 locs
  def get_request_type(params)
        
    req_type = ''
    
    # puts "======================== params in get_request_type is: " + params.inspect + "\n"
    
    if params[:req_type] == nil

        if params[:current_loc] == 'INPROCESS' && ( params[:home_lib] != 'HOOVER' || params[:home_lib] != 'LAW' ) 
        
            req_type = 'REQ-INPRO'

        elsif params[:current_loc] == 'CHECKEDOUT' && params[:home_lib] != 'SAL' # covered below
        
            req_type = 'REQ-RECALL'

        elsif params[:current_loc] == 'ON-ORDER' && ( params[:home_lib] != 'HOOVER' || params[:home_lib] != 'LAW' ) 
      
            # May need to exclude some things here, but how do we get library???
            req_type = 'REQ-ONORDM'
                                
        elsif params[:home_lib] == 'HOOVER'
        
            if params[:current_loc] == 'INPROCESS'
            
                req_type = 'REQ-HVINPR'

            elsif params[:current_loc] == 'ON-ORDER'
            
                req_type = 'REQ-HVORD'

            end
            
        elsif params[:home_lib] == 'LAW'
        
            if params[:current_loc] == 'INPROCESS'
            
                req_type = 'REQ-LWINPR'

            elsif params[:current_loc] == 'ON-ORDER'
            
                req_type = 'REQ-LAWORD'

            end
                           
        elsif params[:home_lib] == 'HOPKINS' && params[:current_loc] == 'STACKS'
        
            req_type = 'REQ-HOP'

        elsif params[:home_lib] == 'SAL'
        
            sal_locs_to_test = [ 'STACKS', 'SAL-SERG', 'FED-DOCS', 'SAL-MUSIC' ]

            if sal_locs_to_test.include?( params[:current_loc] ) || params[:current_loc].include?('PAGE-')
            
                req_type = 'REQ-SAL'

            elsif params[:current_loc] == 'CHECKEDOUT'
            
                req_type = 'RECALL-SL'

            elsif params[:current_loc] == 'UNCAT'
            
                req_type = 'REQ-INPRO'

            end

        elsif params[:home_lib] == 'SAL-NEWARK'
        
            if params[:current_loc] == 'CHECKEDOUT'
            
                req_type = 'RECALL-SN'

            else

                req_type = 'REQ-SALNWK'

            end
                     
        # Changed this one, which originally made everything "REQ-RECALL", which really 
        # makes no sense             
        elsif params[:home_lib] == 'SAL3' # Do we need more options here??
                  
          req_type = 'REQ-SAL3' 

        # Do we need a final else here in case anything slips through?
             
        end 
        
    else

        req_type = params[:req_type]            

    end # check whether params[:req_type] is nil
    
    # puts "==================== request type at end of get_req_type is: " + req_type + "\n"
   
    return req_type
    
  end # get_request_type
  
  # Method item_include. Take home library, home location and current location
  # Return true or false depending on whether item should be included in item array.
  # This may get very elaborate
  def item_include?( home_lib, home_loc, current_loc )
    
    # puts "==================== home loc and current loc in item include: " + home_loc + " " + current_loc + "\n"
    
    
    # First test for certain libs and return true if we have them
    if ['SAL', 'SAL3', 'SAL-NEWARK', 'HOPKINS'].include?(home_lib)
      return true
    # Now test for certain SPEC-COLL combinations (may be more to add)
    elsif home_lib == 'SPEC-COLL' && home_loc =~ /.*\-30/
      return true   
    # For all others return false if home and current locs match  
    elsif home_loc == current_loc
      return false
    # Return true if we get this far without deciding  
    else
      return true
    end
    
  end # item_include
  
  # Method get_sw_info. Gets and parses all info from SearchWorks .request call
  # Inputs: params from request, ckey, home_lib
  # Output: bib_info string and sorted array of item entries to use in view
  def get_sw_info(params, ckey, home_lib)
    
    url = Sw_lookup_pre + ckey + Sw_lookup_suf
  
    # Method scope vars to hold data we want
  
    bib_info = ''
  
    items_hash = Hash.new
  
    # Open URL document
    doc = Nokogiri::XML(open(url))
  
    #===== Get all bib info fields that are present
  
    if doc.xpath("//record/author")
       bib_info = bib_info + ' ' + doc.xpath("//record/author").text
    end
  
    if doc.xpath("//record/title")
       bib_info = bib_info + ' ' + doc.xpath("//record/title").text
    end
     
    if doc.xpath("//record/pub_info")
       bib_info = bib_info + ' ' + doc.xpath("//record/pub_info").text
    end
  
    if doc.xpath("//record/physical_description")
       bib_info = bib_info + ' ' + doc.xpath("//record/physical_description").text
    end
  
    #===== Get array of all symphony item entries ( item_details/item )
  
    items_from_sym = doc.xpath("//item_details/item")
    
    # puts "======== items from sym: " + items_from_sym.inspect + "\n"
  
    # Put Symphony item info into hash with item_id as key and current loc as value
  
    sym_cur_locs = {}
  
    # Iterate over Symphony item array and put info in hash with item_id as key and 
    # current loc as value
    
    items_from_sym.each do |item|
       if item.to_s =~ /.*?<id>(.*?)<\/id>.*?\<location\>(.*?)\<\/location\>.*$/m
          sym_cur_locs[$1] = $2
       end
    end
  
    #===== Get array of all sw item entries (item_display_fields/item_display)
  
    items_from_sw = doc.xpath("//item_display_fields/item_display")

    # puts "======== items from sw: " + items_from_sw.inspect + "\n"

    # Iterate over SW item entries array and add appropriate info to items_hash
    # that combines current loc info from Symphony with other item info from SW
  
    items_from_sw.each do |item|
        
      item_string = item.to_s
      item_string.gsub!(/\<.*?\>/, '')
      
      # 0 - item_id | 1 - home_lib | 2 - home_loc | 3 - current_loc | 4 - shelving rule? | 5 - base call num? | 6 - ? | 7 - 008? | 8 - call num | 9 - shelfkey
      entry_arr = item_string.split(/ \-\|\- /)
      
      # Add only items for home lib and only if they pass item inclusion test        
      if entry_arr[1] == home_lib && item_include?(entry_arr[1], entry_arr[2], sym_cur_locs[entry_arr[0]])
          items_hash = get_items_hash( params,
            items_hash, entry_arr[0], entry_arr[8], home_lib,
            entry_arr[2], sym_cur_locs[entry_arr[0]], entry_arr[9] )
      end

    end # do each item from sw
      
    # puts "======== items hash: " + items_hash.inspect + "\n"  
  
    #===== Sort the items
  
    items_sorted = items_hash.sort_by {|key, shelf_key| shelf_key[:shelf_key]}
    
    # puts "======== items sorted: " + items_sorted.inspect + "\n"  
    
    #===== Make hat + pipe delimited array of strings with name, value, and label for checkboxes
  
    items = get_items( items_sorted )
  
    #===== Return bib_info string and items array
  
    return bib_info, items
  
  end # get_sw_info

    
  # Method to add items to a hash of hashes. Takes hash as input and returns same hash
  # with new hash added. May need to add due date here
  def get_items_hash( params, items, barcode, call_num, library, home_loc, current_loc, shelf_key )

    # puts "params in get_items_hash is: " + params.inspect
    
    # If no current loc, make it the same as home_loc
    
    if current_loc.nil?
      current_loc = home_loc
    end
  
    items.store( barcode, Hash.new() )
    items[barcode].store( :call_num, call_num )
    items[barcode].store( :home_lib, library )
    items[barcode].store( :home_loc, home_loc )
    items[barcode].store( :current_loc, current_loc )
    items[barcode].store( :req_type, get_request_type( params ) ) 
    items[barcode].store( :shelf_key, shelf_key)

    return items # this is the updated hash we got initally

  end

  # Method get_items. Takes sorted items array and makes another array that contains delimited strings
  # with "^" separating name, value, and label of the checkbox we will create on the form
  # Note that we need to create a hash, keyed on unique barcode, then sort the hash on a "shelf key", 
  # which returns an array, then turn that array info another array to get just the pieces of data
  # we need for the checkboxes. Must be a less kludgy way of doing all this, but we are using rather
  # unusual data for the checkboxes because each has to provide what amounts to a separate set of
  # form fields for our multiple requests.
  def get_items( items_sorted )
    
    items = Array.new()

    items_sorted.each do |a| 
      barcode = a[0]  
      home_lib = ''                 
      call_num = ''                   
      home_loc = ''
      current_loc = '' 
      req_type = ''
      a[1].each{ |k,v|      
        if k == :call_num         
          call_num = v unless v.nil?                               
        elsif  k == :current_loc    
          current_loc = v unless v.nil?           
        elsif k == :home_loc    
          home_loc = v unless v.nil?
        elsif k == :home_lib
          home_lib = v unless v.nil?
        elsif k == :req_type
          req_type = v unless v.nil?
        end                      
      } 
      # First level separated by "^" is barcode + all info + call num + home_loc + current_loc
      # Not sure but we need the last two pulled out separately to determine how we display items
      items.push( barcode + '^' + barcode + '|' + home_lib + '|' + call_num + '|' + home_loc + '|' + current_loc + '|' + req_type + '^' + call_num + '^' + home_loc + '^' + current_loc )             

    end  
    
    return items
    
  end
  
  # Method get_results. Take delimited string returned from Symphony that contains info for each
  # item and put it into a hash with msg number as key and call nos. etc as values. 
  def get_results( response )
    
    # Remove any trailing CR and leading and trailing spaces
    response.chomp!.strip!
    
    msgs = {}

    # Single item response won't include '^' but should include > 1 '|'. Not sure this
    # will be enough to distinguish proper response from system problems
    if response.include?('^') || response.index(/.*?\|.*?\|.*$/) # at least two vertical bars
      
      # 36105129254244|DS793 .H6 Z477 2006 V.57|722^36105129254251|DS793 .H6 Z477 2006 V.56|209 
      
      items = response.split('^')
      
      # 36105129254244|DS793 .H6 Z477 2006 V.57|722
      # 36105129254251|DS793 .H6 Z477 2006 V.56|209

      items.each { |item|
        fields = item.split('|') unless item.nil?
        
        # Assign to vars just to make things easier to read
        key = fields[2]
        value = fields[0] + '|' + fields[1]
        if ! msgs.has_key?(key)
          msgs[key] = value
        else
          msgs[key] = msgs[key] + '^' + value
        end
        }
    elsif response.eql?('2')
    
      msgs['2'] = response # This is invalid user reponse
    
    else
      
       msgs['000'] = response 
       
    end      
    
    # puts "message hash in get_results is: "
    # msgs.each do |k,v|
    #  puts k.to_s + " => " + v.to_s
    # end
          
    return msgs    
    
  end # get_results
  
  

  
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
      pickup_libs_hash.merge!({' [Select One From List Below] ' => 'NONE'})
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
    
    # puts "at start of get_fields for requestdef"
    
    fields_hash = {}
    
    request_def.fields.each do |f|
      fields_hash.merge!({f.field_name => f.field_label})
    end    
    
    # Add req/hold field if necessary (need to add more strings to test here)
    
    if ! items.nil?
    
      if items.to_s.include?('^CHECKEDOUT') || items.to_s.include?('^INPROCESS') || items.to_s.include?('^ON-ORDER')
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

  # Method join_hash. Take a hash and return its elements joined by two delimiters
  # Used to turn a params hash into a param string: key1=value1&key2=value2
  # Note that we are excluding two elements from original params hash
  def join_params_hash(hash, delim_1, delim_2)

    keys = Array.new
    hash.each do |a,b|
      # First, we need to eliminate parms that should not be passed along in a redirect URL
      # because they were not in the original URL
      # Need to escape strings here; this gets tricky; seems like we just need to replace
      # ampersands at this point, otherwise other punctuation gets messed up, such as slashes
      # if a.to_s != 'items' && a.to_s != 'item_id' && a.to_s != 'request_def' && a.to_s != 'pickupkey'
      if a.to_s != 'items' && a.to_s && a.to_s != 'request_def' && a.to_s != 'pickupkey'
        if b.nil? # deal with nil values!
          b = ""
        end
        bc = b.gsub('&', '%26')
        keys << [a.to_s, bc.to_s].join(delim_1)
      end
    end
    #end      
    return keys.join(delim_2)
    
  end # join_params_hash    
  
  # Method add_items. Add the items array to the parm_list as a single encoded
  # string 
  def add_items( parm_list, items )
    
    require 'cgi'
    
    item_string = ''
    
    items.each do |item| 
      item.gsub!(/\n+/, " ")
      item.gsub!(/\s+/, " ")
      item.strip!
      if item_string == ''
        item_string = item_string + CGI::escape(item)  
      else
        item_string = item_string + '%5E' +CGI::escape(item)        
      end 
    end
      
      
    return parm_list + '&items=' + item_string  
    
  end # add_items
  
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
    
    #------ Library_id or univ_id
    
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
    
    # ------- Not Needed After
    
    if ! params['not_needed_after'].nil?
      
      if params['not_needed_after'] !~  /^[01][0-9]\/[0-9]{2}\/[0-9]{4}$/ 
        error_msgs.push('Not Needed After field must contain a date in the form MM/DD/YYYY')
      end
      
    end  
    
    # -------- Items: should always have an items field so it should never be nil
    
    if params['items'].nil? || params['items'].empty?
        error_msgs.push('Please select at least one item.')    
    end
    
    # -------- Pickup library should not be NONE 
    
    if params['pickup_lib'].eql?('NONE')
      error_msgs.push( 'Please select a pickup library.' )
    end

    
    
    
    return error_msgs
      
  end # check_fields

  
end