# frozen_string_literal: true

# A mailer for sending OTP challenge emails
class UserMailer < ApplicationMailer
  # Send an email with a link to change a patron's PIN
  def otp_challenge(user, token)
    @user = user
    @token = token

    mail(
      to: user.email,
      subject: 'Your one-time code'
    )
  end
end
