# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # ================ Protected methods from here ====================
  protected 
  
  def is_authenticated?
    if request.env['WEBAUTH_USER'] != nil
      return true
    else
         flash[:notice] = "webauth_user env var is " + request.env['WEBAUTH_USER']
      redirect_to '/requests/not_authenticated'
    end
  end 
    

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
end
