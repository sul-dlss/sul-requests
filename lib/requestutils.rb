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
    
    # Did this another way in syminfo.get_soc_home_loc
    # Add home loc for certain current locs - this is a kludge
    #if SOC_CUR_LOCS_AS_HOME_LOCS.include?(parms_hash[:current_loc]) &&
    #  parms_hash[:home_loc].blank?
    #  parms_hash[:home_loc] = parms_hash[:current_loc]
    #end

    # Change nil to empty string - must be a better way to do this!
    parms_hash.each_pair { |key, value|
      if value.nil?
        parms_hash[key] = ''
      end
    }  

    return parms_hash
    
    # puts "=========== Socrates parms hash is: " + parms_hash.inspect 

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
      
    #----- Locations at other libs that should get NON-PAGE form
    elsif NON_PAGE_LOCS.include?(current_loc)  || current_loc =~ /-LOAN/
      req_def = 'NON-PAGE'
      
    end # check for library or locations 
    
    return req_def   
    
  end # get_req_def    
  
  
  # Take current_loc and other info (?) and return req_hold or req_recall
  # Note that this is going to happen before user fills out form. In the case
  # of checked-out items we need to override with user's choice in PL/SQL.
  # This is ridiculously complicated but there seems to be no alternative because
  # we are using a single form for multiple items
  def get_rec_hold_type ( current_loc, req_hold_parm )
    
    req_type = 'REQ-HOLD' # make this the default
    
    # ---- NOT_ON_SHELF automatically RECALL if authenticated
    
    if NOT_ON_SHELF_LOCS.include?( current_loc ) || current_loc =~ /\-LOAN/
      if @is_authenticated       
        req_type = 'REQ-RECALL'     
      end   
    elsif MISSING_LOCS.include?( current_loc ) || current_loc == 'NEWBOOKS'
      if @is_authenticated       
        req_type = 'REQ-RECALL'     
      end       
    elsif CHECKED_OUT_LOCS.include?( current_loc)
      # This applies only for Socrates records where authentication will 
      # provide a "REQ-RECALL" parameter.
      if ! req_hold_parm.blank?
        req_type = req_hold_parm  
      end
        
    end
     
    return req_type
    
  end
  
  
  
  # Method get_request_type. Take parameters and analyze them to figure out
  # a request type. Note that we need to call this method for every item and the
  # req_type differ for each item and may not match the req_type parm passed in. 
  # We also need to set the req_type for the form as a whole, however, so we know
  # how the initial form ought to display. Or is that necessary? Yes, it seems, because
  # req_type might be used in get_pickup_lib. This gets very complicated because it's 
  # for multiple purposes. In particular, when we set the req_type for items, we need
  # to pick up a completely separate hold_recall parameter from the form in some
  # cases
  # TODO: Add logic for get_request_type that accounts for authentication
  def get_request_type(home_lib, current_loc, req_type_parm, extras = {} )

    req_type = 'UNDEFINED'

     # puts "======================== home_lib in get_request_type is: " + home_lib.inspect + "\n"
     # puts "======================== current_loc in get_request_type is: " + current_loc.inspect + "\n"
     # puts "======================== req_type_param in get_request_type is: " + req_type_parm.inspect + "\n"
     # puts "============ home_loc is: " + extras[:home_loc].inspect

    # First cover items where the current location is the determining factor

    if current_loc == 'INPROCESS' && ! ['HOOVER', 'LAW'].include?( home_lib )

        req_type = 'REQ-INPRO'

    # Should cover all except SAL and SAL-NEWARK
    elsif ( REC_HOLD_LOCS.include?(current_loc) ||
          current_loc =~ /-LOAN/ ) &&
          ! ['SAL', 'SAL-NEWARK'].include?(home_lib) # covered below

        req_type = get_rec_hold_type( current_loc, req_type_parm )

    elsif current_loc == 'ON-ORDER' && ! ['HOOVER', 'LAW'].include?( home_lib )

        # May need to exclude some things here, but how do we get library???
        req_type = 'REQ-ONORDM'

    # Then cover Hoover

    elsif home_lib == 'HOOVER'

        if current_loc == 'INPROCESS'

            req_type = 'REQ-HVINPR'

        elsif current_loc == 'ON-ORDER'

            req_type = 'REQ-HVORD'

        elsif current_loc =~ /.*?-30/
          
            req_type = 'SAL3-TO-HL'

        end

    # Then cover LAW

    elsif home_lib == 'LAW'

        if current_loc == 'INPROCESS'

            req_type = 'REQ-LWINPR'

        elsif current_loc == 'ON-ORDER'

            req_type = 'REQ-LAWORD'

        end

    # Then cover HOPKINS/STACKS

    elsif home_lib == 'HOPKINS' && current_loc == 'STACKS'

        req_type = 'REQ-HOP'

    # Then SPEC-COLL as home lib with -30 location or SAL3-TO-SP req_type (from Socrates)

    elsif home_lib == 'SPEC-COLL' 
        
        if ( extras.has_key?(:home_loc) && extras[:home_loc] =~ /.*?-30$/ ) ||
          req_type_parm.to_s == 'SAL3-TO-SP'
          
          req_type = 'SAL3-TO-SP' 
          
        end
                                               
    
    # SAL

    elsif home_lib == 'SAL'

        if SAL_ON_SHELF_LOCS.include?( current_loc ) ||
          current_loc =~ /PAGE-/ 

            req_type = 'REQ-SAL'

        elsif CHECKED_OUT_LOCS.include?(current_loc) ||
          current_loc =~ /-LOAN/

            req_type = 'RECALL-SL'

        elsif current_loc == 'UNCAT'

            req_type = 'REQ-INPRO'

        end

    # SAL-NEWARK

    elsif home_lib == 'SAL-NEWARK'

        if CHECKED_OUT_LOCS.include?(current_loc) ||
          current_loc =~ /-LOAN/

            req_type = 'RECALL-SN'

        else

            req_type = 'REQ-SALNWK'

        end

    # SAL3

    elsif home_lib == 'SAL3' # Do we need more options here??

      req_type = 'REQ-SAL3'

    end


    # puts "==================== request type at end of get_req_type is: " + req_type + "\n"

    return req_type

  end # get_request_type
  
  # Method get_pickup_key. Determine the pickup_key, which indicates the pickup libraries to display
  # from the home_lib, current_loc, and req_type
  def get_pickup_key( home_lib, home_loc, current_loc, req_type )
    
    pickupkey = ''
    
    # TODO: Make sure logic covers every case & that order is correct
    
    if home_lib.upcase ==  'HOOVER' || home_lib.upcase == 'LAW'
      pickupkey = home_lib
    elsif current_loc[0..4] == 'PAGE-'
      pickupkey = current_loc[5..current_loc.length]
    elsif ! home_loc.blank? && home_loc[0..4] == 'PAGE-'
      pickupkey = home_loc[5..home_loc.length]
    elsif ! home_loc.blank? && home_loc =~ /^(.*)\-30$/
      pickupkey = $1  
    elsif ! req_type.blank? && req_type[0..7] == 'SAL3-TO-'
      pickupkey = req_type[8..req_type.length]      
    end
    
    if pickupkey.blank?
      pickupkey = 'ALL'
    end
    
    return pickupkey
    
  end # get_pickup_key  
  
end