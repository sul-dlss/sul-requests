# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  
  #TODO: Set up rescue_from for various exceptions
  rescue_from Exception, :with => :handle_exception
  # See http://m.onkey.org/2008/7/20/rescue-from-dispatching for info about rescue_from
  #rescue_from ActionController::RoutingError, :with => :route_not_found
  




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
  
  #TODO: Set up exception handling for various exceptions 
  #TODO: Write exception text to a log
  #def route_not_found(exception)
  #  flash[:system_problem] = 'Page not found - 500 ' + exception
  #  render :template => 'requests/app_problem', :status => :not_found
  #end
  
  #TODO: Implement method to handle Exception
  # Note that the exception statement here may give too much info for users
  # so just provide a general message and let the email/log give details
  def handle_exception(exception)
    flash[:system_problem] = 'There was an application problem that makes it impossible to process 
                              your request. We have sent a report about this problem.'
    #ExceptionMailer.exception_report('message')
    ExceptionMailer.deliver_exception_report(exception,
          clean_backtrace(exception),
          session.instance_variable_get("@data"),
          params,
          request.env)
    render :template => 'requests/app_problem', :status => :not_found
  end

  private
     def log_error(exception)
        super
        ExceptionMailer.deliver_exception_report(exception,
          clean_backtrace(exception),
          session.instance_variable_get("@data"),
          params,
          request.env
        )
     end
  

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
end
