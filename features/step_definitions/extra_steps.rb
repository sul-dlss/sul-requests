# Extra webrat steps

#When /^I land on (.+) with ckey="(.+)" and current_loc="(.+)" and req_type="(.)" and item_id="(.+)"$/ do |page_name, ckey, current_loc, req_type, item_id|
#  visit path_to(page_name ( :ckey => ckey, :req_type => req_type, :current_loc => current_loc, :item_id => item_id ) ) 
#end

When /^I land on requests\/new with ckey="([^\"]*)" and req_type="([^\"]*)" and current_loc="([^\"]*)" and item_id="([^\"]*)" and home_lib="([^\"]*)"$/ do |arg1, arg2, arg3, arg4, arg5|
   visit ( 'requests/new', :get,  {:ckey => arg1, :req_type => arg2, :current_loc => arg3, :item_id => arg4, :home_lib => arg5} ) 
end

# This is one without item id
When /^I land on requests\/new with ckey="([^\"]*)" and req_type="([^\"]*)" and current_loc="([^\"]*)" and home_lib="([^\"]*)"$/ do |arg1, arg2, arg3, arg4|
   visit ( 'requests/new', :get,  {:ckey => arg1, :req_type => arg2, :current_loc => arg3, :home_lib => arg4} ) 
end



# Following is just for testing and can be eliminated
#When /^I land on requests\/newx with ckey="([^\"]*)"$/ do |arg1|
#   visit ('requests/newx', :get, {:ckey => arg1}) 
#end

#When /^I land on requests\/newx$/ do
#  visit ('requests/newx', :get, {:ckey => '12345'} )
#end