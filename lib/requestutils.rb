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
    
    # Add home loc for certain current locs - this is a kludge
    if SOC_CUR_LOCS_AS_HOME_LOCS.include?(parms_hash[:current_loc]) &&
      parms_hash[:home_loc].blank?
      parms_hash[:home_loc] = parms_hash[:current_loc]
    end

    # Change nil to empty string - must be a better way to do this!
    parms_hash.each_pair { |key, value|
      if value.nil?
        parms_hash[key] = ''
      end
    }  

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
      
    #----- Locations at other libs that should get NON-PAGE form
    elsif NON_PAGE_LOCS.include?(current_loc)  || current_loc =~ /-LOAN/
      req_def = 'NON-PAGE'
      
    end # check for library or locations 
    
    return req_def   
    
  end # get_req_def    
  
  # Method get_request_type. Take parameters and analyze them to figure out
  # a request type. Note that we need to call this method for every item and the
  # req_type differ for each item and may not match the req_type parm passed in
  def get_request_type(params)

    req_type = ''

    # puts "======================== params in get_request_type is: " + params.inspect + "\n"

    # First cover items where the current location is the determining factor

    if params[:current_loc] == 'INPROCESS' && ! ['HOOVER', 'LAW'].include?( params[:home_lib] )

        req_type = 'REQ-INPRO'

    # Should cover all except SAL and SAL-NEWARKL
    elsif ( CHECKED_OUT_LOCS.include?(params[:current_loc]) ||
          params[:current_loc] =~ /-LOAN/ ) &&
          ! ['SAL', 'SAL-NEWARK'].include?(params[:home_lib]) # covered below

        req_type = 'REQ-RECALL'

    elsif params[:current_loc] == 'ON-ORDER' && ! ['HOOVER', 'LAW'].include?( params[:home_lib] )

        # May need to exclude some things here, but how do we get library???
        req_type = 'REQ-ONORDM'

    # Then cover Hoover

    elsif params[:home_lib] == 'HOOVER'

        if params[:current_loc] == 'INPROCESS'

            req_type = 'REQ-HVINPR'

        elsif params[:current_loc] == 'ON-ORDER'

            req_type = 'REQ-HVORD'

        elsif params[:current_loc] =~ /.*?-30/
          
            req_type = 'SAL3-TO-HL'

        end

    # Then cover LAW

    elsif params[:home_lib] == 'LAW'

        if params[:current_loc] == 'INPROCESS'

            req_type = 'REQ-LWINPR'

        elsif params[:current_loc] == 'ON-ORDER'

            req_type = 'REQ-LAWORD'

        end

    # Then cover HOPKINS/STACKS

    elsif params[:home_lib] == 'HOPKINS' && params[:current_loc] == 'STACKS'

        req_type = 'REQ-HOP'

    # Then SPEC-COLL as home lib with -30 location or SAL3-TO-SP req_type (from Socrates)

    elsif params[:home_lib] == 'SPEC-COLL' && ( params[:home_loc].to_s =~ /.*?-30$/ ||
                                                params[:req_type].to_s == 'SAL3-TO-SP' )
        req_type = 'SAL3-TO-SP'                                                
    
    # SAL

    elsif params[:home_lib] == 'SAL'

        if SAL_ON_SHELF_LOCS.include?( params[:current_loc] ) ||
          params[:current_loc].include?('PAGE-') 

            req_type = 'REQ-SAL'

        elsif CHECKED_OUT_LOCS.include?(params[:current_loc]) ||
          params[:current_loc] =~ /-LOAN/

            req_type = 'RECALL-SL'

        elsif params[:current_loc] == 'UNCAT'

            req_type = 'REQ-INPRO'

        end

    # SAL-NEWARK

    elsif params[:home_lib] == 'SAL-NEWARK'

        if CHECKED_OUT_LOCS.include?(params[:current_loc]) ||
          params[:current_loc] =~ /-LOAN/

            req_type = 'RECALL-SN'

        else

            req_type = 'REQ-SALNWK'

        end

    # SAL3

    elsif params[:home_lib] == 'SAL3' # Do we need more options here??

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