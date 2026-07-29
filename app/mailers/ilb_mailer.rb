# frozen_string_literal: true

###
#  Mailer class to send an email to InterLibrary Borrowing (ILB) staff when a request fails to write a transaction to ILLiad
###
class IlbMailer < ApplicationMailer
  def failed_ilb_notification(patron_request_item, illiad_response = nil)
    @patron_request = patron_request_item.patron_request
    @illiad_response = illiad_response

    mail(
      to: Settings.illiad_email_address,
      from: Settings.libraries.default.contact_info.email,
      subject: 'ILLiad request problem, please remediate'
    )
  end

  def updated_ilb_notification(patron, illiad_request, form_fields)
    @patron = patron
    @illiad_request = illiad_request
    @form_fields = form_fields
    mail(
      to: Settings.illiad_email_address,
      cc: patron.email,
      from: Settings.libraries.default.contact_info.email,
      subject: 'ILLiad request update, please remediate'
    )
  end
end
