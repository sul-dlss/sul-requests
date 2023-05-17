# frozen_string_literal: true

##
# A factory class to return the appropriate RequestStatusMailer
# method based on failure status and request type
class RequestStatusMailerFactory
  class << self
    def for(request)
      if request.ils_response.usererr_code.present? && !request.is_a?(MediatedPage)
        email_for_user_error(request)
      else
        email_for_request_class(request)
      end
    end

    private

    def email_for_user_error(request)
      error_code = request.ils_response.usererr_code

      if mailer_class.respond_to?(:"request_status_for_#{error_code.downcase}")
        mailer_class.send(:"request_status_for_#{error_code.downcase}", request)
      else
        Honeybadger.notify("Unknown ILS Error #{error_code} for request #{request.id}")
        mailer_class.generic_ils_error(request)
      end
    end

    def email_for_request_class(request)
      mailer_class.send(:"request_status_for_#{request.class.to_s.downcase}", request)
    end

    def mailer_class
      RequestStatusMailer
    end
  end
end
