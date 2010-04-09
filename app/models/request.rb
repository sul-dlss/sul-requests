class Request < Tableless
  
  include Requestutils
  
  attr_reader :params, :ckey, :item_id, :items, :home_lib, :current_loc, :home_loc, :req_type, :request_def, 
              :redir_check, :pickupkey, :patron_name, :patron_email, :univ_id, :library_id, 
              :pickup_lib, :not_needed_after, :due_date, :hold_recall, :vol_num, :call_num, 
              :source, :return_url, :comments
              
  attr_accessor :library_id, :items_checked, :home_loc, :pickupkey
  
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
    @home_loc = @params[:home_loc]
    @req_type = get_request_type(@params[:home_lib], @params[:current_loc], @params[:req_type], {:home_loc => @home_loc })
    @request_def = get_req_def(@home_lib, @current_loc )
    @redir_check = check_auth_redir(@params)
    #@pickupkey = get_pickup_key( @home_lib, @current_loc, @home_loc, @req_type )
    @pickupkey = @params[:pickupkey] 
    @pickup_lib = @params[:pickup_lib]
    @not_needed_after = @params[:not_needed_after]
    @due_date = @params[:due_date]
    @hold_recall = @params[:hold_recall]
    @vol_num = @params[:vol_num]
    @call_num = @params[:call_num]
    @comments = @params[:comments]
    @source = @params[:source]
    @return_url = get_return_url(@source, @params[:return_url], request_env)
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
      patron_email =  request_env['WEBAUTH_LDAP_MAIL']   
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
        
  end # get_univ_id
  
  # Get URL needed to return to SW record. It may be passed in as a param, in which 
  # case just return. If not passed in, check that we are coming from SW and set it
  # from the http_referer.
  # TODO: This probably needs work to cover all cases
  def get_return_url(source, return_url, env)

    if return_url.blank?
      if source = 'SW' && 
        ( ! env['HTTP_REFERER'].nil? && env['HTTP_REFERER'] =~ /^.*?searchworks.*$/ )
        return_url = env['HTTP_REFERER']     
      end
    end 
    
    return return_url
    
  end
    
  
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
  

end
