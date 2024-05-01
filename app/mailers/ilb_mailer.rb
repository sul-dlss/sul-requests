# frozen_string_literal: true

###
#  Mailer class to send an email to InterLibrary Borrowing (ILB) staff when a request fails to write a transaction to ILLiad
###
class IlbMailer < ApplicationMailer
  def ilb_notification(request)
    @request = request
    mail(
      to: Settings.illiad_email_address,
      from: Settings.libraries.default.contact_info.email,
      subject: 'ILLiad request problem, please remediate'
    )
  end

  def failed_ilb_notification(patron_request, illiad_response = nil)
    @patron_request = patron_request
    @illiad_response = illiad_response

    mail(
      to: Settings.illiad_email_address,
      from: Settings.libraries.default.contact_info.email,
      subject: 'ILLiad request problem, please remediate'
    )
  end
end
