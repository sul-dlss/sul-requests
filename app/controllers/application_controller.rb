class ApplicationController < ActionController::Base
  protect_from_forgery
  
  helper :all # include all helpers, all the time
  
  include Squash::Ruby::ControllerMethods

  #TODO: Set up rescue_from for various exceptions
  rescue_from Exception, :with => :handle_exception
  #rescue_from Exception with: :handle_exception
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
  
  # See http://maintainablesoftware.com/articles/rails_logging_tips#reducing-log-file-size
  EXCEPTIONS_NOT_LOGGED = ['ActionController::UnknownAction',
                         'ActionController::RoutingError']
  def log_error(exc)
    super unless EXCEPTIONS_NOT_LOGGED.include?(exc.class.name)
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
    notify_squash exception

    case exception
      when ActionController::RoutingError, ActionController::UnknownController, 
        #ActionController::UnknownAction
        ::AbstractController::ActionNotFound
            
        proto = 'http://'
        
        if request.env['SSL']
          proto = 'https://'
        end
        
        flash[:system_problem] = "<p>Requested page: " + proto + request.env['HTTP_HOST'].to_str +
          request.env['REQUEST_URI'].to_str + '</p>' +
          'The page you requested was not found. If you entered this URL into your browser, ' +
          'please check that it is correct. If you found the URL on a Web page, ' +
          'notify the owner of the page about the problem.'
                
        render :template => 'requests/app_problem', :status => :not_found
        
      else  
    
        #TODO: Find a way to make the msg here reference msg 000. Just do a lookup??
        flash[:system_problem] = 'There was an application problem that makes it impossible to process 
                              your request. We have sent a report about this problem.'
          
        render :template => 'requests/app_problem', :status => :not_found
    
    end # case
    
  end

end
