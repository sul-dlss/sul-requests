# frozen_string_literal: true

# A mailer for sending PIN reset emails
class ResetPinsMailer < ApplicationMailer
  default from: 'sul-privileges@stanford.edu'

  # Send an email with a link to change a patron's PIN
  def reset_pin
    @patron = params[:patron]
    @url = change_pin_with_token_url(
      token: @patron.pin_reset_token,
      referrer: params[:referrer]
    )

    mail(
      to: email_address_with_name(@patron.email, @patron.display_name),
      subject: t('reset_pins_mailer.subject')
    )
  end
end
