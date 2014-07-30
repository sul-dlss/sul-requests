module EnvironmentConstants
  
 # Prefix and suffix for SW lookup; these surround ckey to look up
 #if RAILS_ENV == 'production'
  SW_LOOKUP_PRE = 'http://searchworks.stanford.edu/view/'
  SW_LOOKUP_SUF = '.request'
 
  # Prefix for Sirsi Web Services lookup; may need prod + other but do just prod for now
  WS_LOOKUP_SERVER = ''
  WS_LOOKUP_PATH_INFO = '/'
  
# Info for Symphony lookup
 #if RAILS_ENV == 'production'
  SYMPHONY_OAS = ''
  SYMPHONY_PATH_INFO = ''
   
 # For proxy lookup script
   PROXY_LOOKUP = '.../proxy.pl?libid=xyz' 
end
