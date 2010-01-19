# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  


  # ================ Protected methods from here ====================
  protected 
  
  def is_authenticated?
    if request.env['HTTP_HOST'] != 'localhost:3000'
      # This should be all we need to check for authentication on a WebAuth'd server
      # unauth'd users should see server 
      if request.env['WEBAUTH_USER'] != nil
        @is_authenticated = true
        return true
      else
        redirect_to '/requests/not_authenticated'
        # @is_authenticated = false
      end      
    end
  end 
  

     

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
end
