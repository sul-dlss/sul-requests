# frozen_string_literal: true

###
#  Mailer class to send emails that Aeon ought to be able to do.
###
class AeonMailer < ApplicationMailer
  def repeated_requests(request_groups)
    return if request_groups.blank?

    @request_groups = request_groups
    mail(
      to: Settings.libraries['SPEC-COLL'].contact_info.email,
      subject: 'Repeated Aeon Requests Notification'
    )
  end
end
