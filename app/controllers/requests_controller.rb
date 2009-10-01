class RequestsController < ApplicationController
  
    
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
    user = get_user
    @request.patron_name = user[:patron_name]
    @request.library_id = user[:library_id]
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
    @pickup_libs_arr =  [['[Select One From List Below]', 'NONE'],
    ['Art', 'ART'],
    ['Biology [Falconer]', 'BIOLOGY'],
    ['Chemistry/Chemical Engineering [Swain]', 'CHEMCHMENG'],
    ['Earth Sciences [Branner]', 'EARTH-SCI'],
    ['East Asia Library', 'EAST-ASIA'],
    ['Education [Cubberley]', 'EDUCATION'],
    ['Engineering', 'ENG'],
    ['Green [Humanities, Social Sciences]', 'GREEN'],
    ['Hopkins Marine Station Library [Miller]', 'HOPKINS'],
    ['Law [Crown]', 'LAW'],
    ['Math And Computer Science', 'MATH-CS'],
    ['Music', 'MUSIC'],
    ['Physics', 'PHYSICS']
    ]
    # Get the form type and then the text for the form
    form_def = get_form_def( params[:home_lib], params[:current_loc], params[:req_type])
    @form = Form.find_by_form_id( form_def ) # change this when the rest is set up
        
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
    redirect_to :controller => 'requests', :action => 'confirm'
  end
 
  # Method confirm. 
  def confirm
  end
  
  # Protected methods from here 
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
      user = { :patron_name => 'Jonathan Lavigne', :library_id => '2000000603' }
    else
      user = { :patron_name => request.env['WEBAUTH_USER'], :library_id => '' }
    end
  
    return user
  end

  # Method get_bib_info. Take a ckey and return array of bib info to display on the form. 
  def get_bib_info( ckey )
    require 'marc'
    require 'open-uri'
    
    # Read the record and change to array
    reader = MARC::XMLReader.new(open('http://searchworks-test.stanford.edu/view/' + ckey + '.xml') ).to_a
    
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
  def get_form_def ( home_lib, current_loc, req_type )
    
    # First figure out whether we have a generic SUL library or a special library

    if home_lib.upcase != 'HOOVER' && home_lib.upcase != 'LAW' && home_lib.upcase[0..2] != 'SAL'
      home_lib = 'SUL'
    end
    
    # Then figure out if the location should be ANY or something special
    # Need to think more about this. Not sure what locs should fall through here and
    # whether 'ANY' is what we need

    if current_loc.upcase != 'CHECKEDOUT' && current_loc.upcase != 'STACKS'
      current_loc = 'ANY'     
    end
    
    # For the moment just send back the req_type we get in
    form_type = req_type
   
    # Need quite a lot logic here to figure out which request type we have 
    
 
    
    return form_def   
    
  end
  
  # Method get_form_elements. Need to think about this. Should we put all information in 
  # a request_type structure, since we need to take data from what we now have in both request_type
  # and form structures. Seems like we shouldn't necessary repeat the data structures we have now if
  # they're not going to make sense. 
  def get_form_elements( home_lib, current_lib, req_type )
    
    
    
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
