class ExceptionMailer < ActionMailer::Base

  def exception_report(exception, trace, session, params, env, sent_on = Time.now)
      @recipients = 'jlavigne@stanford.edu'
      @from = 'jlavigne@stanford.edu'
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
end