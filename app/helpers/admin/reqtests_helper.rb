module Admin::ReqtestsHelper
  
  def parse_url( url, item )

    # Get rid of any '%20') string; may be more trailing crud
    url.gsub!("'%20)'", "")
    url.gsub!("%20')", "")
    url.gsub!("'%20)", "")
    url.gsub!("%20", "") # always last
    
    # Pull out string after p_data=

    if ( url =~ /.*?p_data=(.*)/ )
      url = $1
    end

    # Get rid of leading "|" if any

    if ( url =~ /^\|(.*$)/ )
      url = $1
    end

    # Split into array on |
    parms = Array.new()

    parms = url.split(/\|/)
    
    if parms[item].nil?
      return ''
    else
      return parms[item]
    end

  end

 

end
