# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/approval_status_mailer
class RequestStatusMailerPreview < ActionMailer::Preview
  def approval_status
    RequestStatusMailer.request_approval_status(Request.last)
  end
end
