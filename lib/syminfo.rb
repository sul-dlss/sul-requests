class Syminfo
  
  # Provide a Symphony information object that contains bibliographic and item data
  # retrieved from SearchWorks. The item information includes live lookup data from
  # Symphony 
      
  require 'nokogiri'
  require 'open-uri'

  include Requestutils
  
  attr_reader :items, :bib_info, :cur_locs, :home_loc
   
  # Method to take parameters and return bib_info string, items array, and 
  # cur_locs array to include on the request form. We get these either by doing 
  # a SearchWorks lookup or by parsing the data we already if we are just
  # redisplaying the input screen, e.g., because of failed validations
  def initialize(params, home_lib, home_loc )
        
    if params[:bib_info].nil? && params[:items].nil? && params[:cur_locs].nil?   
      @bib_info, @items, @cur_locs, @home_loc  = get_sw_info(params, params[:ckey], home_lib, home_loc )     
    else  
      @bib_info = params[:bib_info]
      @items = get_items_from_params(params[:items])
      @cur_locs = get_cur_locs_from_params(params[:cur_locs])
      @home_loc = params[:home_loc]
    end  
    
  end
  
  protected
  
  # Method to take a string of items delimited by "-!-" and return an array
  def get_items_from_params(items_string)
    
    # Note that final -!- doesn't matter and won't return and empty element    
    items_array = items_string.split(/-!-/)
     
    return items_array

  end # get_items from_params_array
  
  # Method to take a string of current_locs delimited by "-!-" and return an array
  def get_cur_locs_from_params(cur_locs_string)
    
    cur_locs_array = cur_locs_string.split(/-!-/)
    
    return cur_locs_array
    
  end
  
  # Method to add items to a hash of hashes. Takes hash as input and returns same hash
  # with new hash added. May need to add due date here
  def get_items_hash( params, items, barcode, call_num, library, home_loc, current_loc, shelf_key )

    # puts " ================== params in get_items_hash is: " + params.inspect
    
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
  def get_sw_info(params, ckey, home_lib, home_loc )
        
    url = SW_LOOKUP_PRE + ckey + SW_LOOKUP_SUF
  
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
    
    #puts "======== items from sym: " + items_from_sym.inspect + "\n"
  
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
    
    items_from_sw.each_with_index do |item, index|
        
      item_string = item.to_s
      item_string.gsub!(/\<.*?\>/, '')
      
      # 0 - item_id | 1 - home_lib | 2 - home_loc | 3 - current_loc | 4 - shelving rule? | 5 - base call num? | 6 - ? | 7 - 008? | 8 - call num | 9 - shelfkey
      entry_arr = item_string.split(/ \-\|\- /)
      
      # puts "======== Entry array in get_sw_info is: " + entry_arr.inspect
      
      # Set the home loc to the first in the array if we didn't get a home_loc parm
      # TODO: Need to add home loc as a parm in Socrates or logic here won't work
      # TODO: for some Socrates records
      if index == 0 && home_loc.nil?
        home_loc = entry_arr[2]
      end
      
      # Add only items where home lib + home_loc match what we have
      # from the parms passed in and only if they pass item inclusion test  

      # puts "=========== lib values / home_locs: " + entry_arr[1] + " = " + home_lib + " / " + entry_arr[2] + " = " + home_loc
      if ( entry_arr[1] == home_lib && entry_arr[2] == home_loc ) && 
             item_include?(entry_arr[1], entry_arr[2], sym_locs_hash[entry_arr[0]])
          items_hash = get_items_hash( params,
            items_hash, entry_arr[0], entry_arr[8], home_lib,
            entry_arr[2], sym_locs_hash[entry_arr[0]], entry_arr[9] )
          # Also add to cur_locs_arr if home loc doesn't match cur loc
          if entry_arr[2] != sym_locs_hash[entry_arr[0]] && ! sym_locs_hash[entry_arr[0]].nil?
            cur_locs_arr.push( sym_locs_hash[entry_arr[0]]) 
          end
      end

    end # do each item from sw
        
    #===== Sort the items
  
    items_sorted = items_hash.sort_by {|key, shelf_key| shelf_key[:shelf_key]}
    
    # puts "======== items sorted: " + items_sorted.inspect + "\n"  
    
    #===== Make hat + pipe delimited array of strings with name, value, and label for checkboxes
  
    items = get_items( items_sorted )
  
    #===== Return bib_info string, items array, and sym_locs_arr
  
    return bib_info, items, cur_locs_arr, home_loc
  
  end # get_sw_info

end