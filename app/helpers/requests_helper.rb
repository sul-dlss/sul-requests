module RequestsHelper
  
  require 'cgi'
  
  # Take a request instance variable and create a link to the auth'd version of the new form
  # The various values in the instance var come from the parms of the original request
  # Probably a better way to do this but could not get at contents of "request" object
  # with .inspect .query_params or anything else even though, when I got an error message,
  # it seemed to say that "request" was a "Request" object. So this method manually goes
  # through all the possible request parameters which is a subset of what's in the model
  def link_to_auth_request(request)
       
    # request.inspect
    
    link = '/auth/requests/new?'
    
    # Add all the fields we have in this request
    
    if request.ckey != nil
      link = link + 'ckey=' + CGI::escape(request.ckey) + '&'
    end
    
    if request.call_num != nil
      link = link + 'call_num=' + CGI::escape(request.call_num) + '&' 
    end
    
    if request.home_lib != nil
      link = link + 'home_lib=' + CGI::escape(request.home_lib) + '&'
    end
    
    if request.current_loc != nil
      link = link + 'current_loc=' + CGI::escape(request.current_loc) + '&' 
    end
    
    if request.current_loc != nil
      link = link + 'home_loc=' + CGI::escape(request.home_loc) + '&' 
    end
    
    if request.item_id != nil
      link = link + 'item_id=' + CGI::escape(request.item_id) + '&'
    end
    
    if request.not_needed_after != nil
      link = link + 'not_needed_after=' + request.not_needed_after + '&'
    end
    
    if request.due_date != nil
      link = link + 'due_date=' + request.due_date + '&'
    end
    
    if request.req_type != nil
      link = link + 'req_type=' + CGI::escape(request.req_type) + '&'
    end
    
    if request.source != nil
      link = link + 'source=' + request.source + '&'
    end
    
    if request.return_url != nil
      link = link + 'return_url=' + CGI::escape(request.return_url) + '&'
    end
    
    # Strip out the final &
    
    if link =~ /.*?\&$/
      link = link.chop
    end
    
    
    return link
    
  end
  
  def link_for_cancel(source, return_url)
    
    # puts "====== request.referer is: " + request.referrer
    # puts "====== request remote host in: " + request.remote_host.inspect
    # need to set referrer when we first call app and then not change it if it's set
    
    if source == 'SO'
      link = 'javascript:self.close()'
    elsif source == 'SW' && ! return_url.blank? && return_url =~ /^http/
      link = return_url
    else
      link = 'javascript:history.go(-1)'
    end
    
  end
  
  # Take a message from the messages table, which may be blank, and a string of items
  # and return the appropriate text for the header that precedes the list of items.
  # If there's no message in the messages table we need to get the text from the first
  # entry in the list. We also need to have a default if we can't find the text from
  # the item.
  def failed_item_header( msg_from_table, item_list, default_msg )
    
    # Default msg is 003. Should be 'Your request was not completed.'
    heading_to_return = default_msg
    
    if msg_from_table.blank?
      
      # 36105073409570|D410 .I752 V.16 1998| User already has a hold on this 
      # material^36105070716209|D410 .I752 V.14(1996)| User already has a hold on
      # this material^36105070716191|D410 .I752 V.13(1995)| User already has a hold on
      # this material
      
      items = item_list.split( /\^/)
    
      fields = items[0].split(/\|/)

      if ! fields[2].nil?
        heading_to_return = heading_to_return + ' System message is: ' + fields[2]
      end
      
    else
      
      heading_to_return = msg_from_table
      
    end
    
    return heading_to_return
    
  end
  
end
