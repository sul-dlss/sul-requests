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
    
    # Get the request definition, form elements, and list of fields
    request_def = get_req_def( params[:home_lib], params[:current_loc], params[:req_type])
    # puts "request_def is:" + request_def
    @requestdef = Requestdef.find_by_name( request_def )
    @fields = get_fields_for_requestdef( @requestdef )
    
    # Get the pickupkey then the pickup_libs
    pickupkey = get_pickup_key( params[:home_lib], params[:current_loc], params[:req_type])       
    @pickup_libs_hash = get_pickup_libs( pickupkey)
    
    # Get remaining fields from parameters
    @request.item = get_bib_info(params[:ckey])
    @request.ckey = (params[:ckey])
    @request.req_type = (params[:req_type])
    @request.due_date = (params[:due_date])
    @request.not_needed_after = (params[:not_needed_after])
    @request.call_num = (params[:call_num])
    @request.pickup_lib = (params[:pickup_lib])
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
    
    # raise params.inspect
    
    # Set up application server and other vars
    symphony_oas = 'http://zaph.stanford.edu:9081'
    path_info = '/pls/sirwebdad/func_request_webservice.make_request?'
    parm_list = URI.escape( join_hash( params[:request], '=', '&' ) )

     
    # Run stored procedure through http (need to check on best way of doing this ).
    # Should we try by running stored proc directly through a db connection defined in .yml file?
    
    url = URI.parse( symphony_oas + path_info + parm_list )
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.get( path_info + parm_list )
    }
       
    flash[:notice] = "Got to create action.<P>Result is: " + res.body + " <br>Param string is: " + parm_list
    # redirect_to requests_path
    # This needs work. For requests path it's OK. For auth/requests path Rails insists on 
    # going to show.html.erb. Kludge is to create show.html.erb in views/auth/requests but this
    # is idiotic. Logged this in Jira as symreq-3
    redirect_to :controller => 'requests', :action => 'confirm'
  end
 
  # Remove this, which goes to confirmation page and instead make "show.html.erb" the
  # confirmation page so default rails route for create action (it seems) will
  # bring up that page
  # Method confirm. 
  # def confirm
  # end
  
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

  

  # Method get_form_elements. Need to think about this. Should we put all information in 
  # a request_type structure, since we need to take data from what we now have in both request_type
  # and form structures. Seems like we shouldn't necessary repeat the data structures we have now if
  # they're not going to make sense. 
  def get_form_elements( home_lib, current_loc, req_type )
    
    
    
  end
   
  # Method get_bib_info. Take a ckey and return array of bib info to display on the form. 
  def get_bib_info( ckey )
    require 'marc'
    require 'rubygems'
    require 'net/http'
    
    # Read the record and change to array; specify nokogiri as parser

    reader = MARC::XMLReader.new(StringIO.new(Net::HTTP.get(URI.parse('http://searchworks-test.stanford.edu/view/' + ckey + '.xml'))), :parser=>'nokogiri').to_a
    record = reader[0] # Should have only record, since we used CKEY

    # Set up fields to get and bib_info string
    fields_to_get = [ '100', '110', '245', '260', '300']
    bib_info = Array.new

    # Iterate over list of fields to get
    fields_to_get.each do |field_num| 
 
      # Put all instances of a field into an array
      field_instances = Array.new

      record.find_all{|f| (field_num) === f.tag}.each do |instance| 
        field_instances.push( instance.to_s ) unless instance.to_s.nil?
      end

      # Clean up all elements of field array and put into bib_info array
      bib_info.push( cleanup_field( field_instances ) );

    end # end fields_to_get

    return bib_info

  end # get_bib_info
  
  # Method get_form_text. Take a key of some sort and return a hash of text elements to use in the form
  # that are fetched from a database where different form types are defined
  # NEEDS WORK, since it's not returning the proper data
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
    
    elsif current_loc.upcase == 'STACKS' || current_loc =~ /.*?\-30$/ ||

      current_loc =~ /^PAGE-/ 
    
      if req_type.upcase == 'REQ-HOP'
        
        req_def = 'REQ-HOPKINS'
        
      elsif req_type.upcase == 'REQ-SAL'
        
        req_def = 'SAL'
        
      elsif req_type.upcase == 'REQ-SAL3'
      
        req_def = 'SAL3'
      
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

  def get_fields_for_requestdef( request_def )
    
    puts "at start of get_fields for requestdef"
    
    fields_hash = {}
    
    request_def.fields.each do |f|
      puts "field name is: " + f.field_name
      fields_hash.merge!({f.field_name => f.field_label})
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
  def join_hash(hash, delim_1, delim_2)
    keys = Array.new
    hash.each {|a,b| keys << [a.to_s, b.to_s].join(delim_1)}
    return keys.join(delim_2)
  end    
  
  
end