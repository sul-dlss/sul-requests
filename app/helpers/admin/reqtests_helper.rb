module Admin::ReqtestsHelper
  
  def parse_url( url, item )

    # Get rid of any %20 strings
    url.gsub("%20", "")

    # Get rid of trailing "')"
    if ( url =~ /^(.*?)'\)$/ )
      url = $1
    end
    
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

    return parms[item]

  end

end
