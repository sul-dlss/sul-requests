module Requestutils
  
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
  
end