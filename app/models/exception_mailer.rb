class ExceptionMailer < ActionMailer::Base

  MAILTO = 'jlavigne@stanford.edu'
  MAILFROM = 'jlavigne@stanford.edu'
  # Mail a report about an exception
  def exception_report(exception, trace, session, params, env, sent_on = Time.now)
      @recipients = MAILTO
      @from = MAILFROM
      @subject = "*** Symphony Requests Exception Report: #{env['REQUEST_URI']}"
      @sent_on = sent_on
      @body = {
        :exception => exception,
        :trace => trace,
        :session => session,
        :params => params,
        :env => env
      }
  end
 
  # Mail a report about an application problem that is not an exception
  def problem_report(params, response, sent_on = Time.now)
      @recipients = MAILTO
      @from = MAILFROM
      @subject = "**** Symphony Requests Application Problem Report"
      @sent_on = sent_on
      @body = {
        :params => params,
        :response => response
      }
    
  end
 end