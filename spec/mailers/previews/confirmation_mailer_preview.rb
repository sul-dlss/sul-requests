# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/confirmation_mailer
class ConfirmationMailerPreview < ActionMailer::Preview
  def confirmation
    ConfirmationMailer.request_confirmation(Request.last)
  end
end
