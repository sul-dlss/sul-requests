# frozen_string_literal: true

###
#  Mailer class to send an email to InterLibrary Borrowing (ILB) staff when a request fails to write a transaction to ILLiad
###
class IlbMailer < ApplicationMailer
  def ilb_notification(request)
    @request = request
    mail(
      to: Settings.illiad_email_address,
      from: SULRequests::Application.config.contact_info['default'][:email],
      subject: 'Scan request problem, please remediate'
    )
  end
end
