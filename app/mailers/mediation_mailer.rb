# frozen_string_literal: true

###
#  Mailer class to send emails to mediators after requests have been submitted
###
class MediationMailer < ApplicationMailer
  def mediator_notification(request)
    @request = request
    @mediation_url = root_url
    mail(
      to: request.mediator_notification_email_address,
      from: from_address,
      subject:
    )
  end

  private

  def from_address
    contact_info[:email]
  end

  def subject
    I18n.t(
      'confirmation_email.mediated_page.mediator_subject',
      title: @request.item_title,
      default: I18n.t('confirmation_email.request.subject')
    )
  end

  def contact_info
    Settings.locations[@request.origin_location_code]&.contact_info ||
      Settings.libraries[@request.origin_library_code]&.contact_info ||
      Settings.libraries['default'].contact_info
  end
end
