module RequestsHelper
  
  # Take a request instance variable and create a link to the auth'd version of the new form
  # The various values in the instance var come from the parms of the original request
  # Probably a better way to do this but could not get at contents of "request" object
  # with .inspect .query_params or anything else even though, when I got an error message,
  # it seemed to say that "request" was a "Request" object. So this method manually goes
  # through all the possible request parameters which is a subset of what's in the model
  def link_to_auth_request(request)
       
    request.inspect
    
    link = '/auth/requests/new?'
    
    # Add all the fields we have in this request
    
    if request.ckey != nil
      link = link + 'ckey=' + request.ckey + '&'
    end
    
    if request.call_num != nil
      link = link + 'call_num=' + request.call_num + '&' 
    end
    
    if request.home_lib != nil
      link = link + 'home_lib=' + request.home_lib + '&'
    end
    
    if request.current_loc != nil
      link = link + 'current_loc=' + request.current_loc + '&' 
    end
    
    if request.item_id != nil
      link = link + 'item_id=' + request.item_id + '&'
    end
    
    if request.not_needed_after != nil
      link = link + 'not_needed_after=' + request.not_needed_after + '&'
    end
    
    if request.due_date != nil
      link = link + 'due_date=' + request.due_date + '&'
    end
    
    if request.req_type != nil
      link = link + 'req_type=' + request.req_type + '&'
    end
    
    # Strip out the final &
    
    if link =~ /.*?\&$/
      link = link.chop
    end
    
    
    return link
    
  end
  
end
