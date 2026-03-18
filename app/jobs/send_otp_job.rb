# frozen_string_literal: true

##
# Rails Job to submit a hold request to Folio for processing
class SendOtpJob < ApplicationJob
  queue_as :default

  def perform(email)
    user = User.find_or_create_by(email: email)

    raise 'Unable to send OTP challenge for authenticated users' if user.sunetid || user.library_id

    UserMailer.otp_challenge(user, user.totp.now).deliver_now
  end
end
