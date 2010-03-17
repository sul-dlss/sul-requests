class Syminfo
  
  # Provide a Symphony information object that contains bibliographic and item data
  # retrieved from SearchWorks. The item information includes live lookup data from
  # Symphony 
      
  require 'nokogiri'
  require 'open-uri'
  #require 'Requestmod'
  
  attr_reader :items, :bib_info, :cur_locs
  
  # Constants for this module - note that -dev and -test both have unpredictable 
  # availability at the moment and this application is unusable if the server 
  # selected here is down.
  Sw_lookup_pre = 'http://searchworks-test.stanford.edu/view/'
  #Sw_lookup_pre = 'http://searchworks-dev.stanford.edu:3000/view/'
  Sw_lookup_suf = '.request'
 
  # Method to take parameters and return bib_info string, items array, and 
  # cur_locs array to include on the request form. 
  def initialize(params, home_lib )
    
    if params[:bib_info].nil? && params[:items].nil? && params[:cur_locs].nil?   
      @bib_info, @items, @cur_locs  = get_sw_info(params, params[:ckey], home_lib )     
    else  
      @bib_info = params[:bib_info]
      @items = get_items_from_params(params[:items])
      @cur_locs = params[:cur_locs]
    end  
    
  end
  
  protected
  
  # Method to take a string of items delimited by "-!-" and return an array
  def get_items_from_params(items_string)
    
    # Note that final -!- doesn't matter and won't return and empty element    
    items_array = items_string.split(/-!-/)
     
    return items_array

  end # get_items from_params_array
  
  
  # Method to add items to a hash of hashes. Takes hash as input and returns same hash
  # with new hash added. May need to add due date here
  def get_items_hash( params, items, barcode, call_num, library, home_loc, current_loc, shelf_key )

    # puts "params in get_items_hash is: " + params.inspect
    
    # If no current loc, make it the same as home_loc
    
    if current_loc.nil?
      current_loc = home_loc
    end
  
    items.store( barcode, Hash.new() )
    items[barcode].store( :call_num, call_num )
    items[barcode].store( :home_lib, library )
    items[barcode].store( :home_loc, home_loc )
    items[barcode].store( :current_loc, current_loc )
    items[barcode].store( :req_type, get_request_type( params ) )
    items[barcode].store( :shelf_key, shelf_key)

    return items # this is the updated hash we got initally

  end

  # Method get_items. Takes sorted items array and makes another array that contains delimited strings
  # with "^" separating name, value, and label of the checkbox we will create on the form
  # Note that we need to create a hash, keyed on unique barcode, then sort the hash on a "shelf key", 
  # which returns an array, then turn that array info another array to get just the pieces of data
  # we need for the checkboxes. Must be a less kludgy way of doing all this, but we are using rather
  # unusual data for the checkboxes because each has to provide what amounts to a separate set of
  # form fields for our multiple requests.
  def get_items( items_sorted )
    
    items = Array.new()

    items_sorted.each do |a| 
      barcode = a[0]  
      home_lib = ''                 
      call_num = ''                   
      home_loc = ''
      current_loc = '' 
      req_type = ''
      a[1].each{ |k,v|      
        if k == :call_num         
          call_num = v unless v.nil?                               
        elsif  k == :current_loc    
          current_loc = v unless v.nil?           
        elsif k == :home_loc    
          home_loc = v unless v.nil?
        elsif k == :home_lib
          home_lib = v unless v.nil?
        elsif k == :req_type
          req_type = v unless v.nil?
        end                      
      } 
      # First level separated by "^" is barcode + all info + call num + home_loc + current_loc
      # Not sure but we need the last two pulled out separately to determine how we display items
      items.push( barcode + '^' + barcode + '|' + home_lib + '|' + call_num + '|' + home_loc + '|' + current_loc + '|' + req_type + '^' + call_num + '^' + home_loc + '^' + current_loc )             

    end  
    
    return items
    
  end

  
  # Method item_include. Take home library, home location and current location
  # Return true or false depending on whether item should be included in item array.
  # This may get very elaborate
  def item_include?( home_lib, home_loc, current_loc )
    
    # puts "==================== home loc and current loc in item include: " + home_loc + " " + current_loc + "\n"
    
    
    # First test for certain libs and return true if we have them
    if ['SAL', 'SAL3', 'SAL-NEWARK', 'HOPKINS'].include?(home_lib)
      return true
    # Now test for certain SPEC-COLL combinations (may be more to add)
    elsif home_lib == 'SPEC-COLL' && home_loc =~ /.*\-30/
      return true   
    # For all others return false if home and current locs match  
    elsif home_loc == current_loc
      return false
    # Return true if we get this far without deciding  
    else
      return true
    end
    
  end # item_include  
  
  # Method get_sw_info. Gets and parses all info from SearchWorks .request call
  # Inputs: params from request, ckey, home_lib
  # Output: bib_info string and sorted array of item entries to use in view
  def get_sw_info(params, ckey, home_lib )
    
    url = Sw_lookup_pre + ckey + Sw_lookup_suf
  
    # Method scope vars to hold data we want
  
    bib_info = ''
  
    items_hash = Hash.new
  
    # Open URL document
    doc = Nokogiri::XML(open(url))
  
    #===== Get all bib info fields that are present
  
    if doc.xpath("//record/author")
       bib_info = bib_info + ' ' + doc.xpath("//record/author").text
    end
    
    if doc.xpath("//record/title")
       bib_info = bib_info + ' ' + doc.xpath("//record/title").text
    end
     
    if doc.xpath("//record/pub_info")
       bib_info = bib_info + ' ' + doc.xpath("//record/pub_info").text
    end
  
    if doc.xpath("//record/physical_description")
       bib_info = bib_info + ' ' + doc.xpath("//record/physical_description").text
    end
  
    #===== Get array of all symphony item entries ( item_details/item )
  
    items_from_sym = doc.xpath("//item_details/item")
    
    # puts "======== items from sym: " + items_from_sym.inspect + "\n"
  
    # Put Symphony item info into hash with item_id as key and current loc as value
    # and also create separate cur_locs array with just loc values
  
    sym_locs_hash = {}
    
    items_from_sym.each do |item|
       if item.to_s =~ /.*?<id>(.*?)<\/id>.*?\<location\>(.*?)\<\/location\>.*$/m
          sym_locs_hash[$1] = $2
       end
    end
  
    #===== Get array of all sw item entries (item_display_fields/item_display)
  
    items_from_sw = doc.xpath("//item_display_fields/item_display")

    # puts "======== items from sw: " + items_from_sw.inspect + "\n"

    # Iterate over SW item entries array and add appropriate info to items_hash
    # that combines current loc info from Symphony with other item info from SW
    # also update cur_locs_arr
  
    cur_locs_arr = []
    
    items_from_sw.each do |item|
        
      item_string = item.to_s
      item_string.gsub!(/\<.*?\>/, '')
      
      # 0 - item_id | 1 - home_lib | 2 - home_loc | 3 - current_loc | 4 - shelving rule? | 5 - base call num? | 6 - ? | 7 - 008? | 8 - call num | 9 - shelfkey
      entry_arr = item_string.split(/ \-\|\- /)
      
      # Add only items for home lib and only if they pass item inclusion test        
      if entry_arr[1] == home_lib && item_include?(entry_arr[1], entry_arr[2], sym_locs_hash[entry_arr[0]])
          items_hash = get_items_hash( params,
            items_hash, entry_arr[0], entry_arr[8], home_lib,
            entry_arr[2], sym_locs_hash[entry_arr[0]], entry_arr[9] )
          # Also add to cur_locs_arr if home loc doesn't match cur loc
          if entry_arr[2] != sym_locs_hash[entry_arr[0]]
            cur_locs_arr.push( sym_locs_hash[entry_arr[0]])
          end
      end

    end # do each item from sw
      
    # puts "======== items hash: " + items_hash.inspect + "\n"  
  
    #===== Sort the items
  
    items_sorted = items_hash.sort_by {|key, shelf_key| shelf_key[:shelf_key]}
    
    # puts "======== items sorted: " + items_sorted.inspect + "\n"  
    
    #===== Make hat + pipe delimited array of strings with name, value, and label for checkboxes
  
    items = get_items( items_sorted )
  
    #===== Return bib_info string, items array, and sym_locs_arr
    
    # puts "=============== cur_locs at end of get_sw_info in model is: " + cur_locs_arr.inspect + "\n"
  
    return bib_info, items, cur_locs_arr
  
  end # get_sw_info

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

  
  
  # Make public so we can call it from reqtest controller

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
  
  # Method get_request_type. Take parameters and analyse them to figure out
  # a request type
  def get_request_type(params)
        
    req_type = ''
    
    # puts "======================== params in get_request_type is: " + params.inspect + "\n"
    
    # We need to provide a request type only if we don't already have one in the parameters
    
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
  
  
  
end