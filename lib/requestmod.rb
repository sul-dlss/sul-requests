module Requestmod
  
  # Module for both authenticated and unauthenticated requests
  
  def index
  end

  # Method new. Display a request form, including data retrieved from an XML lookup and user data from 
  # the authentication, if available. The user fills in this from to create a request
  def new
    @request = Request.new
    # raise params.inspect
    # Do not need session ID
    #@request.session_id = get_symphony_session(params[:library], params[:req_type])
    #@request.session_id = get_symphony_session('GREEN', 'REQ-HOLD')
    
    # Get user information
    user = get_user
    @request.patron_name = user[:patron_name]
    @request.patron_email = user[:patron_email]
    @request.library_id = user[:library_id]
    
    # Get req_type - may not be in parms but need for request_def at the moment
    @request.req_type = get_request_type(params)
    
    # Need library for to limit items
    @request.home_lib = (params[:home_lib])
    
    # Get the request definition, form elements, and list of fields
    request_def = get_req_def( params[:home_lib], params[:current_loc], @request.req_type )
    # puts "request_def is:" + request_def
    @requestdef = Requestdef.find_by_name( request_def )
    # @fields = get_fields_for_requestdef( @requestdef )
    
    # Get the pickupkey then the pickup_libs
    pickupkey = get_pickup_key( params[:home_lib], params[:current_loc], @request.req_type )       
    @pickup_libs_hash = get_pickup_libs( pickupkey)
    
    # Get bib info in 2 arrays, one for 900 fields - this is rather involved
    multi_bib_info = get_bib_info(params, params[:ckey], params[:home_lib])
    @request.bib_info = multi_bib_info[0].to_s
    @request.items = multi_bib_info[1] # delimited array
    
    @fields = get_fields_for_requestdef( @requestdef, @request.items )
    
    # Get remaining fields from parameters
    #@request.bib_info = get_bib_info(params[:ckey]).to_s # old
    @request.ckey = (params[:ckey])
    
    # These apply to all items
    @request.pickup_lib = (params[:pickup_lib])
    @request.not_needed_after = (params[:not_needed_after])
    
    # These are item-specific so apply only at the item level
    @request.due_date = (params[:due_date])
    @request.call_num = (params[:call_num])
    @request.home_lib = (params[:home_lib])
    @request.current_loc = (params[:current_loc])
    @request.item_id = (params[:item_id])
         
  end
 
  # Method create. Send user input to Oracle stored procedure that creates
  # a request and sends back either a confirmation or error message
  def create
    
    require 'net/http'
    require 'uri'
    @request = Request.new(params[:request])

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
       
    flash[:notice] = "Got to create action.<P>Result is: " + res.body + " <P>Param string is: " + parm_list
    # redirect_to requests_path
    # This needs work. For requests path it's OK. For auth/requests path Rails insists on 
    # going to show.html.erb. Kludge is to create show.html.erb in views/auth/requests but this
    # is idiotic. Logged this in Jira as symreq-3
    #redirect_to :controller => 'requests', :action => 'confirm'
    render :template => "requests/confirm"
  end
   
  # Method not_authenticated. Just show not_authenticated page
  def not_authenticated
    render :template => "requests/not_authenticated"
  end


  
  # ================ Protected methods from here ====================
  protected
 
  # Method get_symphony_session. Take a library name and a request type, send information to 
  # Symphony, get back a stripped-down request input form, parse out and return the action parameter
  # that's needed to place the request
  # Note: we don't need this anymore since everything will go through apiserver with no http to Symphony
  def get_symphony_session( library, request_type)
    
    require 'net/http'
    require 'uri'
   
    url = URI.parse('http://zaph.stanford.edu/uhtbin/cgisirsi/0/' + library + '/0/64/' + request_type )
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.get('/uhtbin/cgisirsi/0/' + library + '/0/64/' + request_type )
    }
   
    action_parm = ''
    if res.body =~ /^.*?ACTION=(.*?)>.*$/
      action_parm = $1
    end
   
    return action_parm
    
  end
  
  # Method get_user. Get user information, normally from the environment and return as a hash
  def get_user 
    
    if request.env['WEBAUTH_USER'].blank?
       user = { :patron_name => '', :library_id => '', :patron_email => '' }     
       #user = { :patron_name => 'Jonathan Lavigne', :library_id => '2000000603', :patron_email => 'jlavigne@stanford.edu' }     
    else
      user = { :patron_name => request.env['WEBAUTH_USER'], :library_id => '', :patron_email => '' }
    end
  
    return user
  end

  # Method get_request_type. Return the request type based on other parameters if we don't have
  # one included in the parameters. Logic copied from PL/SQL code for display proc. Not sure whether all of 
  # this is still needed for Socrates but might help with SearchWorks
  def get_request_type(params)
    
    req_type = ''
    
   if params[:req_type] == nil

        if params[:current_loc] == 'INPROCESS' && ( params[:home_lib] != 'HOOVER' || params[:home_lib] != 'LAW' ) 
        
            req_type = 'REQ-INPRO'

        elsif params[:current_loc] == 'CHECKEDOUT'
        
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

            if sal_locs_to_test.include?( params[:current_loc] ) || params[:current_loc].include?['PAGE-']
            
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
                     
        elsif params[:home_lib] == 'SAL3'
        
            if params[:current_loc] != 'INPROCESS'
            
                req_type = 'REQ-RECALL' 

            end

        elsif params[:current_loc] == 'CHECKEDOUT'
        
            req_type = 'REQ-RECALL'

        # Do we need a final else here in case anything slips through?
             
        end 
        
    else

        req_type = params[:req_type]            

    end # check whether params[:req_type] is nil

    
    return req_type
    
  end
  
   
  # Method get_bib_info. Take a ckey and return array of bib info to display on the form. 
  def get_bib_info( params, ckey, home_lib )
    require 'marc'
    require 'rubygems'
    require 'net/http'
    
    # Read the record and change to array; specify nokogiri as parser

    reader = MARC::XMLReader.new(StringIO.new(Net::HTTP.get(URI.parse('http://searchworks-test.stanford.edu/view/' + ckey + '.xml'))), :parser=>'nokogiri').to_a
    record = reader[0] # Should have only record, since we used CKEY

    # Set up fields to get and bib_info string
    fields_to_get = [ '100', '110', '245', '260', '300', '999']
    #fields_to_get = [ '100', '110', '245', '260', '300']
    bib_info = Array.new
    items_hash = Hash.new

    # Iterate over list of fields to get
    fields_to_get.each do |field_num| 
 
      # Put all instances of a field into an array
      field_instances = Array.new
      counter = 0

      record.find_all{|f| (field_num) === f.tag}.each do |instance| 
        if field_num == '999' 
          if instance['m'] == home_lib
            # Counter to keep input order but this doesn't actually help
            # will need to use "shelfkey" somehow
            counter = counter +1
            # items, barcode, call_num, library, home_loc, current_loc
            items_hash = get_items_hash( params, items_hash, instance['i'], instance['a'], instance['m'], instance['l'], instance['k'], counter )
          end
        else
          field_instances.push( instance.to_s ) unless instance.to_s.nil?
        end
      end

      # Clean up all elements of field array and put into bib_info array
      bib_info.push( cleanup_field( field_instances ) );

    end # end fields_to_get
    
    # Now sort the items; returns nested array of hashes - will need to use normalized call number here   
    items_sorted = items_hash.sort_by {|key, counter| counter[:counter]}

    # Now make this into a hat + pipe delimited array of strings with name, value, and label for checkboxes
    # Is there a less involved way of doing this?

    items = get_items( items_sorted )

    return bib_info, items
    
    # Returning just one array lets me get back text of fields
    # return bib_info

  end # get_bib_info
  
  # Method to add items to a hash of hashes. Takes hash as input and returns same hash
  # with new hash added. May need to add due date here
  def get_items_hash( params, items, barcode, call_num, library, home_loc, current_loc, counter )

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
    items[barcode].store( :counter, counter)

    return items # this is the updated hash we got initally

  end

  # Method get_items. Takes sorted items array and makes another array that contains delimited strings
  # with "^" separating name, value, and label of the checkbox we will create on the form
  # Note that we need to create a hash, keyed on unique barcode, then sort the hash on a "shelf key", 
  # which returns an array, then turned that array info another array to get just the pieces of data
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
  # item and put it into a hash with msg number as key and call nos. etc as values 
  def get_results( response )
    
    items = response.split('^')

    msgs = {}

    items.each { |item|
      fields = item.split('|')
      # Assign to vars just to make things easier to read
      key = fields[2]
      value = fields[0] + '|' + fields[1]
      puts key + ' => ' + value
      if ! msgs.has_key?(key)
        msgs[key] = value
      else
        msgs[key] = msgs[key] + '^' + value
      end
      }
    
    return msgs    
    
  end
  
  
  # Method get_form_text. Take a key of some sort and return a hash of text elements to use in the form
  # that are fetched from a database where different form types are defined
  # NEEDS WORK, since it's not returning the proper data. Note also that this is pretty
  # muuch useless if each item will a separate request type
  def get_req_def( home_lib, current_loc, req_type )
    
    req_def = ''
    
    # puts "home_lib is: " + home_lib
    # puts "current_loc is: " + current_loc
    # puts "req_type is: " + req_type
    
    # First figure out whether we have a generic SUL library or a special library

    if home_lib.upcase != 'HOOVER' && home_lib.upcase != 'LAW' && home_lib.upcase[0..2] != 'SAL'
      home_lib = 'SUL'
    end
    
    # Main criterion is current_loc, with everything else depending on that

    # =============== CHECKEDOUT
    
    if current_loc.upcase == 'CHECKEDOUT'
      
      # Req type can be either REQ-HOLD or REQ-REQ-RECALL
      
      # --------------- HOLD
      if req_type.upcase == 'REQ-HOLD'  
        
        if home_lib.upcase == 'HOOVER'
          
          req_def = 'HOLD-HOV'
          
        elsif home_lib.upcase == 'LAW'
          
          req_def = 'HOLD-LAW'
          
        else 
          
          req_def = 'HOLD-SUL'
          
        end # home_lib choice
      
      # --------------- RECALL
      
      elsif req_type.upcase == 'REQ-RECALL'  
        
        if home_lib.upcase == 'HOOVER'
          
          req_def = 'RECALL-HOV'
          
        elsif home_lib.upcase == 'LAW'
          
          req_def = 'RECALL-LAW'
          
        else 
          req_def = 'RECALL-SUL'
          
        end # home_lib choice
        
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
        
      # Need to look into the following. Probably irrelevant if we multiple items and fewer forms        
      
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
    
  end
  
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
    
  end
  
  # Method get_pickup_libs. Take a pickupkey and return an hash of one
  # or more pickuplibs. Should have both lib code and label
  def get_pickup_libs( pickupkey)
       
    # See http://apidock.com/rails/ActiveRecord/Base/find/class
    # Example find by associated table
    
    pickup_libs = Library.find(:all,
      :select => 'libraries.lib_code, libraries.lib_descrip',
      :conditions => ['pickupkeys.pickup_key == ?', pickupkey],
      :joins => [:pickupkeys],
      :order => 'libraries.lib_code'   
      )
      
    # Now we put into a hash and return it sorted. Seems like there should
    # be an easier way of getting the list of libraries!! 
      
    pickup_libs_hash = Hash.new
    
    for pickuplib in pickup_libs
      pickup_libs_hash.merge!({pickuplib.lib_descrip => pickuplib.lib_code})  
    end  

    return pickup_libs_hash.sort
    
  end
  
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
    
    if items.to_s.include?('^CHECKEDOUT') || items.to_s.include?('^INPROCESS') || items.to_s.include?('^ON-ORDER')
      fields_hash.merge!({'hold_recall' => 'Request Type'})
    end        
    
    return fields_hash
    
  end
  
  # Method cleanup_field. Take an array containing one or more instances of a field
  # and return an array of elements that strip out tags and delimiters 
  def cleanup_field( field_arr ) 
  
    bib_info = Array.new

    # Iterate over instances, clean up and add to bib_info array
    field_arr.each do |instance|
      # Data starts at col 11
      new_instance = instance.slice(10, instance.length)
      new_instance = new_instance.gsub( /\$.*? /, '')
      bib_info.push(new_instance)

    end

    return bib_info

  end  # cleanup_field
  
  # Method join_hash. Take a hash and return its elements joined by two delimiters
  # Used to turn a params hash into a param string: key1=value1&key2=value2
  # Note that we are excluding two elements from original params hash
  def join_params_hash(hash, delim_1, delim_2)

    keys = Array.new
    hash.each do |a,b|
    # Need to escape strings here; this gets tricky; seems like we just need to replace
    # ampersands at this point, otherwise other punctuation gets messed up, such as slashes
      if a.to_s != 'items' && a.to_s != 'item_id'
        bc = b.gsub('&', '%26')
        keys << [a.to_s, bc.to_s].join(delim_1)
      end
    end
    #end      
    return keys.join(delim_2)
    
  end    
  
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
    
  end
  
  
end