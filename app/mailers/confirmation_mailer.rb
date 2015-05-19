###
#  Mailer class to send confimration emails after requests have been submitted
###
class ConfirmationMailer < ApplicationMailer
  def request_confirmation(request)
    @request = request
    @status_url = success_url
    mail(
      to: request.user.email_address,
      from: from_address,
      subject: subject
    )
  end

  private

  def from_address
    I18n.t(
      "confirmation_email.#{@request.origin.underscore}.from",
      default: I18n.t('confirmation_email.default.from')
    )
  end

  def subject
    I18n.t(
      "confirmation_email.#{@request.class.name.underscore}.subject",
      title: @request.item_title,
      default: I18n.t('confirmation_email.request.subject')
    )
  end

  def success_url
    if !@request.user.webauth_user? && @request.is_a?(TokenEncryptable)
      polymorphic_url([:status, @request], token: @request.encrypted_token)
    else
      polymorphic_url([:status, @request])
    end
  end
end
