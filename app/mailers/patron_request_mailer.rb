# frozen_string_literal: true

###
#  Mailer class to send confirmation emails after requests have
#  been submitted
###
class PatronRequestMailer < ApplicationMailer
  helper :requests
  def confirmation_email(patron_request)
    @patron_request = patron_request
    mail(
      to: @patron_request.patron_email,
      from: from_address,
      subject: "#{@patron_request.item_title} - Stanford University Libraries request confirmation"
    )
  end

  def from_address
    %("Stanford Libraries Requests" <#{@patron_request.contact_info[:email] || 'sul-requests-support@stanford.edu'}>)
  end
end
