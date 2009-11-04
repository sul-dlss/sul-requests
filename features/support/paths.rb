module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in webrat_steps.rb
  #
  def path_to(page_name)
    case page_name
    
    when /the home\s?page/
      '/'

    #when /requests\/new with ckey="([^\"]*)" and req_type="([^\"]*)" and current_loc="([^\"]*)" and item_id="([^\"]*)" and home_lib="([^\"]*)"$/ 
    #requests_new_path(:ckey => $1, :req_type => $2, :current_loc => $3, :item_id => $4, :home_lib =>$5 )

    #when /requests\/newx with with ckey="([^\"]*)"/
    # requests_newx_path(:ckey => $1)

    
    #when /requests\/newx/
    # 'requests/newx'
     
    when /requests/
      '/requests'
      

    
    # Add more mappings here.
    # Here is a more fancy example:
    #
    #   when /^(.*)'s profile page$/i
    #    user_profile_path(User.find_by_login($1))
    
    when /admin\/requestdefs/
      admin_requestdefs_path

    else
      raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
        "Now, go and add a mapping in #{__FILE__}"
    end
  end
end

World(NavigationHelpers)
