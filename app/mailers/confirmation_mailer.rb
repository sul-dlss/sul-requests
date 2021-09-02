# frozen_string_literal: true

###
#  Mailer class to send confirmation emails after requests have been submitted
###
class ConfirmationMailer < ApplicationMailer
  def request_confirmation(request)
    @request = request
    @status_url = success_url
    @contact_info = contact_info
    mail(
      to: request.notification_email_address,
      from: from_address,
      subject: subject
    )
  end

  private

  def from_address
    %("Stanford Libraries Requests" <#{contact_info[:email]}>)
  end

  def subject
    I18n.t(
      "confirmation_email.#{@request.class.name.underscore}.#{@request.origin}.subject",
      title: @request.item_title,
      default: [
        :"confirmation_email.#{@request.class.name.underscore}.subject",
        :'confirmation_email.request.subject'
      ]
    )
  end

  def contact_info
    Settings.locations[@request.origin_location]&.contact_info ||
      Settings.libraries[@request.origin]&.contact_info ||
      Settings.libraries[@request.destination]&.contact_info ||
      Settings.libraries.default.contact_info
  end

  def success_url
    if !@request.user.webauth_user? && @request.is_a?(TokenEncryptable)
      polymorphic_url([:status, @request], token: @request.encrypted_token)
    else
      polymorphic_url([:status, @request])
    end
  end
end
