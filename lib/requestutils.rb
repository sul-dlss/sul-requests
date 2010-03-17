module Requestutils
  
  include Constants
  
  # Take a Socrates URL and parse the delimited string in the p_data parameter
  # to return a set of key/value pairs 
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
    keys = [:session_id, :action_string, :ckey, :home_lib, :current_loc, 
      :call_num, :item_id, :req_type, :due_date]

    parms_hash = Hash[*keys.zip(parms).flatten]
    
    # Get rid of session_id and action_string, which we don't need
    
    parms_hash.delete(:session_id)
    parms_hash.delete(:action_string)

    return parms_hash

  end # parse_soc_url

  # Method get_req_def. Determine request definition from home_lib, current_loc and req_type
  # Make UNDEFINED the default if nothing else turns up.
  def get_req_def( home_lib, current_loc )
    
    req_def = 'UNDEFINED'
    
    #========= First check for requests that depend on library 
   
    #----- SAL
    if home_lib == 'SAL'
      req_def = 'PAGE-SAL'
    
    #----- SAL3 - multiple possibilities here  
    elsif home_lib == 'SAL3'
      
      if current_loc == 'PAGE-MP'
        req_def = 'PAGE-BRANNER'
      else 
        req_def = 'PAGE-SAL3'
      end
    
    #----- SAL-NEWARK  
    elsif home_lib == 'SAL-NEWARK'
      req_def = 'PAGE-SALNEWARK'
   
   #----- HOPKINS   
    elsif home_lib == 'HOPKINS'
      req_def = 'PAGE-HOPKINS'
      
    #----- SPEC-COLL
    elsif home_lib == 'SPEC-COLL'
      req_def = 'PAGE-SPECCOLL'
      
    #----- HV-ARCHIVE
    elsif home_lib == 'HV-ARCHIVE'
      req_def = 'PAGE-HVARCHIVE'
    
    #----- HOOVER
    elsif home_lib == 'HOOVER'
      req_def = 'PAGE-HOOVER'
      
    #----- Location at other libs that should get NON-PAGE form
    elsif NON_PAGE_LOCS.include?(current_loc)  
      req_def = 'NON-PAGE'
      
    end # check for library or locations 
    
    return req_def   
    
  end # get_req_def    
  
end