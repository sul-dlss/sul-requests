# frozen_string_literal: true

##
# Rails Job to submit a hold request to Folio for processing
class SendOtpJob < ApplicationJob
  queue_as :default

  def perform(email)
    user = User.find_or_create_by(email: email)

    if user.sunetid || user.library_id
      Honeybadger.notify('Unable to send OTP challenge for authenticated users')
      return
    end

    UserMailer.otp_challenge(user, user.totp.now).deliver_now
  end
end
