# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  # Helper method to construct a form that returns to the request form. Still in progress
  # and should not be called yet.
  def return_to_request( request )
    
    # Should get one key ":object" and one value, the request object we passed in
    request.each_pair do |k,v|

      # Get all key/value pairs except for items and items_checked
      v.attributes.each_pair do |key, value|   
        if ! value.nil?
          if ! key.eql?('items_checked') && ! key.eql?( 'items' )  
            puts "key is: " + key  + " value is: " +  value  
          end # if key eql
        end # if value nil
      end # attributes each pair
      
      # Now get values from items_checked array
      v.attributes['items_checked'].each do |item| 
        if ! item.nil?
          puts "item is: " + item 
        end
      end
      
    end # request each pair
    
    # Need to construct a set of fields from info above and return it to the view

  end # return to request
  
end

