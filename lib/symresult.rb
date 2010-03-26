class Symresult
  
  # Take parameters from request form, call program running on Symphony machine
  # that makes requests, parse returned response, and set up msgs for confirm page
  # along with raw result to use for debugging
  
  attr_reader :msgs, :parm_list, :result
 
  # Take parameters submitted from a request form and set the msgs hash from the
  # response returned by Symphony, along with the original parameter list, and
  # the raw response string. The latter two are used for debugging and should
  # be written to a log at some point
  # TODO: Write parm list and raw result string to a log
  def initialize(params)
    
    @msgs, @parm_list, @result = get_results(params)
    
  end
  
  private
  
  # Take params submitted by request form, put them into a string that can be sent
  # to the program running on the Symphony server that makes the request, get back
  # the reponse, call other functions that parse the response, and return a msg hash
  # along with the original raw response, which we need temporarily for debugging
  def get_results(params)
    
      # Set up application server and other vars (move to constants?)
      symphony_oas = 'http://zaph.stanford.edu:9081'
      path_info = '/pls/sirwebdad/func_request_webservice.make_request?'
      # First we get the items, then the rest of params without items
      items_checked = params[:request][:items_checked]
      parm_list = URI.escape( get_symphony_params( params[:request], '=', '&' ) )
      parm_list = add_items( parm_list, items_checked)
         
      # puts "=============== parm list for PL/SQL is: " + parm_list + "\n"   
      
      url = URI.parse( symphony_oas + path_info + parm_list )
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.get( path_info + parm_list )
      }
         
      # Get results hash from delimited string returned from Symphony
      msgs = get_msgs( params[:request], res.body ) 
      
      return msgs, parm_list, res.body
    
  end
  
  # Method add_items. Add the items array to the parm_list as a single encoded
  # string 
  def add_items( parm_list, items_checked )
    
    require 'cgi'
    
    item_string = ''
    
    items_checked.each do |item| 
      item.gsub!(/\n+/, " ")
      item.gsub!(/\s+/, " ")
      item.strip!
      if item_string == ''
        item_string = item_string + CGI::escape(item)  
      else
        item_string = item_string + '%5E' +CGI::escape(item)        
      end 
    end
   
    return parm_list + '&items=' + item_string  
    
  end # add_items  
  
  # Method join_params_hash. Take a hash and return its elements joined by two delimiters
  # Used to turn a params hash into a param string: key1=value1&key2=value2
  # Note that we are excluding some elements from original params hash because these 
  # are used on the Rails side but we don't want to send them to Symphony
  def get_symphony_params(hash, delim_1, delim_2)

    keys = Array.new
    hash.each do |a,b|
      # First, we need to eliminate parms that should not be passed along in a redirect URL
      # because they were not in the original URL
      # Need to escape strings here; this gets tricky; seems like we just need to replace
      # ampersands at this point, otherwise other punctuation gets messed up, such as slashes
       if a.to_s != 'items_checked' && a.to_s != 'request_def' && a.to_s != 'pickupkey' &&
         a.to_s != 'source' && a.to_s != 'msg_keys' && a.to_s != 'item_id' && 
         a.to_s != 'items' && a.to_s != 'cur_locs'
         if b.nil? # deal with nil values!
           b = ""
         end
         bc = b.gsub('&', '%26')
         keys << [a.to_s, bc.to_s].join(delim_1)
       end
    end
    #end      
    return keys.join(delim_2)
    
  end # join_params_hash  
  
  
  # Take the response from the program running on the Symphony server that makes
  # the requests, split the returned string into various pieces, and return a msgs
  # hash with the msg number as key and a delimited string as value, containing 
  # item ID and call number. Note that we group items under each msg number key 
  def get_msgs( params, response )
    
    # Remove any trailing CR and leading and trailing spaces
    response.chomp!.strip!
    
    msgs = {}

    # Single item response won't include '^' but should include > 1 '|'. Not sure this
    # will be enough to distinguish proper response from system problems
    #if response.include?('^') || response.index(/.*?\|.*?\|.*$/) # at least two vertical bars
    if response.include?('RESPONSE') && (response.include?('^') ||
                                       response.index(/.*?\|.*?\|.*$/) ) # at least two vertical bars  
      
      # 36105129254244|DS793 .H6 Z477 2006 V.57|722^36105129254251|DS793 .H6 Z477 2006 V.56|209 
      
      items = response.split('^')
      
      # 36105129254244|DS793 .H6 Z477 2006 V.57|722
      # 36105129254251|DS793 .H6 Z477 2006 V.56|209

      items.each { |item|
        fields = item.split('|') unless item.nil?
        
        # Assign to vars just to make things easier to read
        key = fields[3]
        value = fields[1] + '|' + fields[2]
        if ! msgs.has_key?(key)
          msgs[key] = value
        else
          msgs[key] = msgs[key] + '^' + value
        end
        }
    elsif response.eql?('2')
    
      msgs['2'] = response # This is invalid user reponse
    
    else
      
       # Indicates unexpected problem, so mail a report 
      
       msgs['000'] = response 

       ExceptionMailer.deliver_problem_report(params, response )
       
    end      
    
    # puts "message hash in get_results is: "
    # msgs.each do |k,v|
    #  puts k.to_s + " => " + v.to_s
    # end
          
    return msgs    
    
  end # get_results
    
  
end