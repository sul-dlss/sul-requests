# frozen_string_literal: true

##
# A factory class to return the appropriate ApprovalStatusMailer
# method based on failure status and request type
class ApprovalStatusMailerFactory
  class << self
    def for(request)
      if request.symphony_response.usererr_code.present?
        email_for_user_error(request)
      else
        email_for_request_class(request)
      end
    end

    private

    def email_for_user_error(request)
      error_code = request.symphony_response.usererr_code

      if mailer_class.respond_to?(:"approval_status_for_#{error_code.downcase}")
        mailer_class.send(:"approval_status_for_#{error_code.downcase}", request)
      else
        Honeybadger.notify("Unknown Symohony Error #{error_code} for request #{request.id}")
        mailer_class.generic_symphony_error(request)
      end
    end

    def email_for_request_class(request)
      mailer_class.send(:"approval_status_for_#{request.class.to_s.downcase}", request)
    end

    def mailer_class
      ApprovalStatusMailer
    end
  end
end
