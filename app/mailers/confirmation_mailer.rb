# frozen_string_literal: true

###
#  Mailer class to send confirmation emails after requests have been submitted
###
class ConfirmationMailer < ApplicationMailer
  def request_confirmation(request)
    @request = request
    @status_url = success_url
    @contact_info = formatted_contact_info
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
      "confirmation_email.#{@request.class.name.underscore}.subject",
      title: @request.item_title,
      default: I18n.t('confirmation_email.request.subject')
    )
  end

  def contact_info
    contact_info_config[@request.origin_location] ||
      contact_info_config[@request.origin] ||
      contact_info_config[@request.destination] ||
      contact_info_config['default']
  end

  def contact_info_config
    SULRequests::Application.config.contact_info
  end

  def formatted_contact_info
    "  #{contact_info[:phone]}\n  #{contact_info[:email]}"
  end

  def success_url
    if !@request.user.webauth_user? && @request.is_a?(TokenEncryptable)
      polymorphic_url([:status, @request], token: @request.encrypted_token)
    else
      polymorphic_url([:status, @request])
    end
  end
end
