class ExceptionMailer < ActionMailer::Base
  
  # Defaults which will be the same for both types of reports
  default :to => 'jkeck@stanford.edu, dlrueda@stanford.edu', :from => 'no-reply@requests.stanford.edu'

  # Mail a report about an exception
  def exception_report(exception, trace, session, params, env, sent_on = Time.now)
    
      # puts "exception in exception_mailer is " + exception.inspect
      # puts "methods are " + exception.methods.to_s

      @subject = "*** Symphony Requests Exception Report: #{env['REQUEST_URI']}"
      @sent_on = sent_on
      @exception = exception
      @trace = trace
      @session = session
      @params = params
      @env = env
      
      mail(:subject => @subject)
      
  end
 
  # Mail a report about an application problem that is not an exception
  def problem_report(params, response, sent_on = Time.now)
    
    # Instance vars to use in template file
    @subject = "**** Symphony Requests Application Problem Report"
    @sent_on = sent_on
    @params = params,
    @response = response
      
    mail( :subject => @subject)
    
  end
 
end