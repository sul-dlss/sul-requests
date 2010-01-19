module Admin::ReqtestsHelper
  
  def parse_url( url, item )

    # Get rid of any '%20') string; may be more trailing crud
    url.gsub!("'%20)'", "")
    url.gsub!("%20')", "")
    url.gsub!("'%20)", "")
    url.gsub!("%20", "") # always last
    
    # Pull out string after p_data=

    if ( url =~ /.*?p_data=(.*)/ )
      url = $1
    end

    # Get rid of leading "|" if any

    if ( url =~ /^\|(.*$)/ )
      url = $1
    end

    # Split into array on |
    parms = Array.new()

    parms = url.split(/\|/)
    
    if parms[item].nil?
      return ''
    else
      return parms[item]
    end

  end

  # Method get_form_text. Take a key of some sort and return a hash of text elements to use in the form
  # that are fetched from a database where different form types are defined
  # NEEDS WORK, since it's not returning the proper data. Note also that this is pretty
  # muuch useless if each item will a separate request type
  # NOTE: Need to avoid repeating this here!!!!!
  def get_req_def( home_lib, current_loc, req_type )
    
    req_def = 'UNDEFINED'
    
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
      if req_type.upcase == 'REQ-HOLD' || req_type.upcase == 'REQ-RECALL' 
        
        if home_lib.upcase == 'HOOVER'
          
          req_def = 'HOLDREC-HOV'
          
        elsif home_lib.upcase == 'LAW'
          
          req_def = 'HOLDREC-LAW'
          
        else 
          
          req_def = 'HOLDREC-SUL'
          
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


end
