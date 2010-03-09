class Request < Tableless
  
  include Requestutils
  
  attr_reader :params, :ckey, :item_id, :items, :home_lib, :current_loc, :req_type, :request_def, 
              :redir_check, :pickupkey, :patron_name, :patron_email, :univ_id, :library_id, 
              :pickup_lib, :not_needed_after, :due_date, :hold_recall, :call_num, :source
              
  attr_accessor :library_id, :items_checked
  
  def initialize(params, request_env )
    
    @params = get_params(params)
    @patron_name = get_patron_name( @params[:patron_name], request_env )
    @patron_email = get_patron_email( @params[:patron_email], request_env )
    @library_id = @params[:library_id]
    @univ_id = get_univ_id( @params[:univ_id], request_env )
    @ckey = @params[:ckey]
    @item_id = @params[:item_id]
    @items = @params[:items]
    @items_checked = @params[:items_checked]
    @home_lib = @params[:home_lib]
    @current_loc = @params[:current_loc]
    @req_type = get_request_type( @params )
    @request_def = get_req_def(@home_lib, @current_loc, @req_type )
    @redir_check = check_auth_redir(@params)
    #puts "======================== redir check is: " + @redir_check.inspect + "\n"
    @pickupkey = get_pickup_key( @home_lib, @current_loc, @req_type ) 
    #puts "================== params is: " + @params.inspect    
    @pickup_lib = @params[:pickup_lib]
    @not_needed_after = @params[:not_needed_after]
    @due_date = @params[:due_date]
    @hold_recall = @params[:hold_recall]
    @call_num = @params[:call_num]
    @source = @params[:source]
    #@msg_keys = get_msg_keys(cur_locs)      
    #puts "================= msg keys is: " + @msg_keys.inspect + "\n"
  end
  
  # Take params passed to this object and parse p_data string from Socrates into
  # separate key/value pairs. Also add param to indicate source of GET request. Other
  # methods for defining elements of the object depend on this method. 
  def get_params(params)
    
    params_final = {}
    
    if params.has_key?(:p_data)
      params_final = params
      params_soc = parse_soc_url('p_data=' + params[:p_data])
      params_final.delete(:p_data)
      params_final.merge!(params_soc)
      params_final.merge!(:source => 'SO')
    else
      params_final = params
      if ! params.has_key?(:source) # in case this is returning from SO redirect
        params_final.merge!(:source => 'SW')
      end        
    end

    return params_final
    
  end
  
  # Take the patron_name parameter and the request env and return the first 
  # if it's not nil or the the LDAP name from the other if the first is nil
  def get_patron_name( parm_name, request_env )
    
    patron_name = ''
    
    if ! parm_name.blank?
      patron_name = parm_name
    elsif ! request_env['WEBAUTH_LDAP_DISPLAYNAME'].blank?
      patron_name =  request_env['WEBAUTH_LDAP_DISPLAYNAME']    
    end
    
    return patron_name
        
  end # get_patron_name
  
  # Take the patron_email parameter and the request env and return the first
  # if it's not nil or the LDAP email from the other if the first is nil
  def get_patron_email( parm_email, request_env )
    
    patron_email = ''
    
    if ! parm_email.blank?
      patron_email = parm_email
    elsif ! request_env['WEBAUTH_LDAP_MAIL'].blank?
      patron_name =  request_env['WEBAUTH_LDAP_MAIL']    
    end
    
    return patron_email
        
  end # get_patron_email
  
  # Take the univ ID parameter and the request env and return the first
  # if it's not nil or the univ ID from the other if the first is nil
  # TODO Determine whether we want to allow users to change the Univ ID
  def get_univ_id( parm_univ_id, request_env )
    
    univ_id = ''
    
    if ! parm_univ_id.blank?
      univ_id = parm_univ_id
    elsif ! request_env['WEBAUTH_LDAP_SUUNIVID'].blank?
      univ_id =  request_env['WEBAUTH_LDAP_SUUNIVID']    
    end
    
    return univ_id
        
  end # get_patron_email
    
  
  # Method get_request_type. Take parameters and analyse them to figure out
  # a request type
  def get_request_type(params)
        
    req_type = ''
    
    # puts "======================== params in get_request_type is: " + params.inspect + "\n"
    
    if params[:req_type] == nil

        if params[:current_loc] == 'INPROCESS' && ( params[:home_lib] != 'HOOVER' || 
          params[:home_lib] != 'LAW' ) 
        
            req_type = 'REQ-INPRO'

        elsif params[:current_loc] == 'CHECKEDOUT' && params[:home_lib] != 'SAL' # covered below
        
            req_type = 'REQ-RECALL'

        elsif params[:current_loc] == 'ON-ORDER' && ( params[:home_lib] != 'HOOVER' || 
          params[:home_lib] != 'LAW' ) 
      
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

            if sal_locs_to_test.include?( params[:current_loc] ) || 
              params[:current_loc].include?('PAGE-')
            
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

  
  

  # Take params and determine whether or not a redirect to the auth path 
  # is needed. Logic here is a bit complicated.
  def check_auth_redir(params)
      
    # Redir already done so return false
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

end
